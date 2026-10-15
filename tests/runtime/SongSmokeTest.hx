import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;

import funkin.backend.PlayerSettings;
import funkin.data.ClientPrefs;
import funkin.data.Song;
import funkin.states.PlayState;

import openfl.display.Sprite;

/** Runs actual game states/graphics/audio/scripts on native Lime, not an HScript mock. */
class SongSmokeTest extends Sprite
{
	public static function main() openfl.Lib.current.addChild(new SongSmokeTest());
	
	public function new()
	{
		super();
		ClientPrefs.loadDefaultKeys();
		addChild(new SmokeGame(1280, 720, SmokeInit, 60, 60, true));
	}
}

class SmokeGame extends FlxGame
{
	override function onEnterFrame(event:openfl.events.Event):Void
	{
		try
			super.onEnterFrame(event)
		catch (error:Dynamic)
		{
			Sys.println('SMOKE FAIL: ' + Std.string(error) + '\n' + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			Sys.exit(1);
		}
	}
}

class SmokeInit extends FlxState
{
	override function create():Void
	{
		super.create();
		funkin.data.scripts.FunkinIris.InitLogger();
		crowplexus.iris.Iris.error = (message, ?position) -> {
			Sys.println('SMOKE SCRIPT FAIL: ' + Std.string(position) + ' ' + message);
			Sys.exit(2);
		};
		PlayerSettings.init();
		FlxG.sound.playMusic(funkin.Paths.music('freakyMenu'), 0);
		ClientPrefs.lowQuality = Sys.getEnv('SMOKE_QUALITY') != 'high';
		ClientPrefs.gpuCaching = true;
		ClientPrefs.shaders = true;
		ClientPrefs.middleScroll = Sys.getEnv('SMOKE_MODE') == 'middlescroll';
		ClientPrefs.gameplaySettings.set('practice', true);
		ClientPrefs.gameplaySettings.set('botplay', Sys.getEnv('SMOKE_MODE') != 'game-touch');
		funkin.mobile.TouchControls.install();
		if (Sys.getEnv('SMOKE_MODE') == 'touch')
		{
			FlxG.switchState(() -> new TouchProbe());
			return;
		}
		if (Sys.getEnv('SMOKE_MODE') == 'menu-difficulty')
		{
			new MenuDifficultyProbe();
			FlxG.switchState(() -> new funkin.states.FreeplayState());
			return;
		}
		var song = Sys.getEnv('SMOKE_SONG');
		if (song == null) song = 'sussus-moogus';
		PlayState.isStoryMode = false;
		var chart = Sys.getEnv('SMOKE_HARD') == '1' ? song + '-hard' : song;
		PlayState.SONG = Song.loadFromJson(chart, song);
		// Sussus Moogus starts with 12 seconds of silence. Begin just before
		// its first note so the positioning probe also exercises incoming notes.
		if (Sys.getEnv('SMOKE_MODE') == 'middlescroll')
		{
			var firstNote = Math.POSITIVE_INFINITY;
			for (section in PlayState.SONG.notes)
				for (note in section.sectionNotes)
					if (note[1] >= 0) firstNote = Math.min(firstNote, note[0]);
			PlayState.startOnTime = Math.max(1, firstNote - 1000);
		}
		if (Sys.getEnv('SMOKE_MODE') == 'game-touch') new GameTouchProbe();
		if (Sys.getEnv('SMOKE_MODE') == 'middlescroll') new MiddlescrollProbe();
		FlxG.signals.postUpdate.add(checkSong);
		FlxG.switchState(() -> new PlayState());
	}
	
	var frames = 0;
	var entries = 1;
	var menuFrames = 0;
	
	function checkSong():Void
	{
		if (Sys.getEnv('SMOKE_MODE') == 'reentry' && Std.isOfType(FlxG.state, funkin.states.FreeplayState))
		{
			if (++menuFrames == 30)
			{
				var song = Sys.getEnv('SMOKE_SONG');
				if (song == null) song = 'sussus-moogus';
				PlayState.SONG = Song.loadFromJson(Sys.getEnv('SMOKE_HARD') == '1' ? song + '-hard' : song, song);
				FlxG.switchState(() -> new PlayState());
			}
			return;
		}
		if (!Std.isOfType(FlxG.state, PlayState)) return;
		if (++frames >= 300)
		{
			if (Sys.getEnv('SMOKE_MODE') == 'reentry' && entries < 3)
			{
				Sys.println('REENTRY: finished entry ' + entries + ', returning through actual FreeplayState');
				entries++;
				frames = 0;
				menuFrames = 0;
				FlxG.switchState(() -> new funkin.states.FreeplayState());
				return;
			}
			Sys.println('SMOKE PASS: ' + PlayState.SONG.song + ', 300 actual state update/draw frames; lowQuality=' + ClientPrefs.lowQuality);
			if (entries == 3) Sys.println('REENTRY PASS: three song entries with Freeplay menu between them');
			Sys.exit(0);
		}
	}
}
