package funkin.utils;

import funkin.data.Song;

typedef SongDifficultyChoice =
{
	var label:String;
	var index:Int;
	var chart:String;
}

/** Only offer charts which the current song actually ships. */
class SongDifficulty
{
	public static function available():Array<SongDifficultyChoice>
	{
		var choices:Array<SongDifficultyChoice> = [];
		var folder = Paths.formatToSongPath(PlayState.SONG.song);
		for (index in 0...DifficultyUtil.difficulties.length)
		{
			var label = DifficultyUtil.difficulties[index];
			var chart = folder + (label == DifficultyUtil.defaultDifficulty ? '' : '-' + Paths.formatToSongPath(label));
			var key = folder + '/' + chart;
			var exists = openfl.Assets.exists('assets/songs/$key.json', TEXT);
			#if sys
			#if MODS_ALLOWED
			exists = exists || sys.FileSystem.exists(Paths.modsJson(key));
			#end
			exists = exists || sys.FileSystem.exists(Paths.json(key));
			#else
			exists = exists || openfl.Assets.exists(Paths.json(key), TEXT);
			#end
			if (exists) choices.push({label: label, index: index, chart: chart});
		}
		return choices;
	}
	
	public static function currentLabel():String
	{
		return DifficultyUtil.difficulties[PlayState.storyDifficulty] ?? DifficultyUtil.defaultDifficulty;
	}
	
	public static function select(index:Int):Void
	{
		for (choice in available())
		{
			if (choice.index != index) continue;
			// Load before muting/changing the state, so a missing chart cannot half-switch.
			var song = Song.loadFromJson(choice.chart, Paths.formatToSongPath(PlayState.SONG.song));
			PlayState.SONG = song;
			PlayState.storyDifficulty = index;
			PlayState.changedDifficulty = true;
			PlayState.chartingMode = false;
			PlayState.startOnTime = 0;
			PlayState.instance.paused = true;
			FlxG.sound.music.volume = 0;
			PlayState.instance.vocals.volume = 0;
			FlxG.resetState();
			return;
		}
	}
}
