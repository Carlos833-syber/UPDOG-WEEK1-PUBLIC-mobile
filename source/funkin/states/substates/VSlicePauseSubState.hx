package funkin.states.substates;

import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.backend.MusicBeatSubstate;
import funkin.objects.Alphabet;
import funkin.utils.CameraUtil;
import funkin.utils.SongDifficulty;

/**
 * V-Slice's standard pause menu adapted to this engine's states and controls.
 * Upstream attribution and adaptation details are in VSLICE-NOTICE.md.
 */
class VSlicePauseSubState extends MusicBeatSubstate
{
	var entries:Array<PauseEntry> = [];
	var menuText:FlxTypedGroup<Alphabet>;
	var currentEntry:Int = 0;
	var inDifficultyMenu:Bool = false;
	var openDifficulty:Bool;
	var justOpened:Bool = true;
	var leaving:Bool = false;
	var background:FlxSprite;
	var metadata:Array<FlxText> = [];
	var practiceText:FlxText;
	var pauseMusic:FlxSound;
	var age:Float = 0;
	
	public function new(openDifficulty:Bool = false)
	{
		super();
		this.openDifficulty = openDifficulty;
	}
	
	override function create():Void
	{
		cameras = [CameraUtil.lastCamera];
		
		background = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		background.setGraphicSize(FlxG.width, FlxG.height);
		background.updateHitbox();
		background.scrollFactor.set();
		background.alpha = 0;
		add(background);
		
		addMetadata(PlayState.SONG.song);
		addMetadata('Difficulty: ${SongDifficulty.currentLabel()}');
		addMetadata('${PlayState.deathCounter} Blue Balls');
		practiceText = addMetadata('PRACTICE MODE');
		practiceText.visible = PlayState.instance.practiceMode;
		
		menuText = new FlxTypedGroup<Alphabet>();
		add(menuText);
		if (openDifficulty) showDifficulties();
		else showStandardMenu();
		
		// Keep the mod's licensed music; V-Slice's breakfast track is not bundled.
		pauseMusic = FlxG.sound.load(Paths.music('pause_theme'), 0, true);
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		
		super.create();
	}
	
	function addMetadata(text:String):FlxText
	{
		var line = new FlxText(20, 15 + metadata.length * 34, FlxG.width - 40, text, 28);
		line.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, RIGHT);
		line.scrollFactor.set();
		line.alpha = 0;
		metadata.push(line);
		add(line);
		return line;
	}
	
	function showStandardMenu():Void
	{
		inDifficultyMenu = false;
		entries = [
			{label: 'Resume', callback: close},
			{label: 'Restart Song', callback: restartSong},
			{label: 'Change Difficulty', callback: showDifficulties}
		];
		if (!PlayState.instance.practiceMode) entries.push({label: 'Enable Practice Mode', callback: enablePracticeMode});
		entries.push({label: 'Exit to Menu', callback: exitToMenu});
		regenerateMenu();
	}
	
	public function showDifficulties():Void
	{
		inDifficultyMenu = true;
		entries = [];
		for (difficulty in SongDifficulty.available())
		{
			final index = difficulty.index;
			entries.push({label: difficulty.label, callback: () -> selectDifficulty(index)});
		}
		entries.push({label: 'Back', callback: showStandardMenu});
		regenerateMenu();
	}
	
	function regenerateMenu():Void
	{
		for (text in menuText.members)
			if (text != null) text.destroy();
		menuText.clear();
		currentEntry = 0;
		for (i in 0...entries.length)
		{
			var text = new Alphabet(90, 70 * i + 30, entries[i].label, true, false, 0.05, 0.72);
			text.isMenuItem = true;
			text.scrollFactor.set();
			menuText.add(text);
		}
		changeSelection();
	}
	
	function changeSelection(change:Int = 0):Void
	{
		currentEntry = FlxMath.wrap(currentEntry + change, 0, entries.length - 1);
		if (change != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		for (i in 0...menuText.members.length)
		{
			var text = menuText.members[i];
			text.targetY = i - currentEntry;
			text.alpha = i == currentEntry ? 1 : 0.6;
		}
	}
	
	override function update(elapsed:Float):Void
	{
		age += elapsed;
		background.alpha = Math.min(0.6, age * 1.5);
		if (pauseMusic != null) pauseMusic.volume = Math.min(0.75, pauseMusic.volume + elapsed * 0.15);
		for (i in 0...metadata.length)
		{
			var progress = FlxMath.bound((age - i * 0.1) / 0.2, 0, 1);
			metadata[i].alpha = progress;
			metadata[i].y = 15 + i * 34 - (1 - progress) * 24;
		}
		super.update(elapsed);
		
		// An input that opened the substate must not also activate its first item.
		if (justOpened)
		{
			justOpened = false;
			return;
		}
		if (leaving) return;
		if (controls.BACK)
		{
			if (inDifficultyMenu) showStandardMenu();
			else close();
			return;
		}
		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);
		if (controls.ACCEPT) entries[currentEntry].callback();
	}
	
	function enablePracticeMode():Void
	{
		PlayState.instance.practiceMode = true;
		PlayState.changedDifficulty = true;
		practiceText.visible = true;
		showStandardMenu();
	}
	
	function muteSong():Void
	{
		leaving = true;
		PlayState.instance.paused = true;
		if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
		if (PlayState.instance.vocals != null) PlayState.instance.vocals.volume = 0;
	}
	
	function restartSong():Void
	{
		muteSong();
		FlxG.resetState();
	}
	
	function selectDifficulty(index:Int):Void
	{
		muteSong();
		SongDifficulty.select(index);
	}
	
	function exitToMenu():Void
	{
		muteSong();
		PlayState.deathCounter = 0;
		PlayState.seenCutscene = false;
		PlayState.cancelMusicFadeTween();
		PlayState.changedDifficulty = false;
		PlayState.chartingMode = false;
		FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
	
	override function destroy():Void
	{
		if (pauseMusic != null)
		{
			FlxG.sound.list.remove(pauseMusic);
			pauseMusic.destroy();
			pauseMusic = null;
		}
		super.destroy();
	}
}

private typedef PauseEntry =
{
	var label:String;
	var callback:Void->Void;
};
