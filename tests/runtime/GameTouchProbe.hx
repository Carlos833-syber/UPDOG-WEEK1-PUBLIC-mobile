import flixel.FlxG;

import funkin.backend.PlayerSettings;
import funkin.data.ClientPrefs;
import funkin.states.PlayState;

import openfl.events.TouchEvent;

@:access(funkin.states.PlayState)
class GameTouchProbe
{
	var step = 0;
	var started = false;
	var game:PlayState;
	
	public function new()
	{
		FlxG.signals.preUpdate.add(inject);
		FlxG.signals.postUpdate.add(check);
	}
	
	function inject():Void
	{
		if (!Std.isOfType(FlxG.state, PlayState)) return;
		game = cast FlxG.state;
		if (!started && game.subState == null && game.startedCountdown && game.generatedMusic) started = true;
		if (!started) return;
		step++;
		switch (step)
		{
			case 5:
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 20, 160, 400);
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 21, 480, 400);
			case 7:
				TouchProbe.send(TouchEvent.TOUCH_END, 20, 160, 400);
			case 9:
				TouchProbe.send(TouchEvent.TOUCH_END, 21, 480, 400);
			case 11:
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 22, 1200, 40);
			case 12:
				TouchProbe.send(TouchEvent.TOUCH_END, 22, 1200, 40);
			case 15:
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 23, 1060, 630);
			case 16:
				TouchProbe.send(TouchEvent.TOUCH_END, 23, 1060, 630);
			case 23:
				ClientPrefs.mobileFourLaneHitbox = false;
			case 25:
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 24, 150, 400);
			case 27:
				TouchProbe.send(TouchEvent.TOUCH_END, 24, 150, 400);
		}
	}
	
	function check():Void
	{
		if (!started) return;
		var c = PlayerSettings.player1.controls;
		switch (step)
		{
			case 5:
				TouchProbe.expect(c.NOTE_LEFT_P && c.NOTE_DOWN_P, 'two gameplay lanes');
				TouchProbe.expect(game.keysPressed[0] && game.keysPressed[1], 'touch reaches actual PlayState.notePressed without controller mode');
			case 6:
				TouchProbe.expect(c.NOTE_LEFT && c.NOTE_DOWN && !c.NOTE_LEFT_P, 'gameplay sustain input');
			case 7:
				TouchProbe.expect(c.NOTE_LEFT_R && c.NOTE_DOWN, 'gameplay independent release');
			case 11:
				TouchProbe.expect(game.paused && game.subState != null, 'touch pause opens actual pause menu');
			case 19:
				TouchProbe.expect(!game.paused && game.subState == null && !c.NOTE_LEFT && !c.PAUSE, 'resume without stale input/camera');
			case 25:
				TouchProbe.expect(c.NOTE_UP_P && game.keysPressed[2], 'alternative Psych dpad reaches note handler');
			case 29:
				Sys.println('GAME TOUCH PASS: actual PlayState taps/holds, pause/resume and optional Psych dpad');
				Sys.exit(0);
		}
	}
}
