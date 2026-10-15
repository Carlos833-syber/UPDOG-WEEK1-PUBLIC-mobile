import flixel.FlxG;

import funkin.backend.PlayerSettings;
import funkin.data.ClientPrefs;
import funkin.states.PlayState;

import openfl.events.TouchEvent;

@:access(funkin.states.PlayState)
@:access(funkin.states.substates.VSlicePauseSubState)
class GameTouchProbe
{
	var step = 0;
	var started = false;
	var game:PlayState;
	var beforeDifficulty:PlayState;
	
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
			case 29:
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 25, 980, 40);
			case 30:
				TouchProbe.send(TouchEvent.TOUCH_END, 25, 980, 40);
			case 31, 43:
				beforeDifficulty = game;
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 26, 80, 40);
			case 32, 44:
				TouchProbe.send(TouchEvent.TOUCH_END, 26, 80, 40);
			case 35, 39:
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 27, 1060, 630);
			case 36, 40:
				TouchProbe.send(TouchEvent.TOUCH_END, 27, 1060, 630);
			case 47:
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 28, 150, 630);
			case 48:
				TouchProbe.send(TouchEvent.TOUCH_END, 28, 150, 630);
			case 51:
				TouchProbe.send(TouchEvent.TOUCH_BEGIN, 29, 1200, 630);
			case 52:
				TouchProbe.send(TouchEvent.TOUCH_END, 29, 1200, 630);
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
				TouchProbe.expect(game.paused
					&& Std.isOfType(game.subState, funkin.states.substates.VSlicePauseSubState), 'touch pause opens V-Slice menu');
			case 19:
				TouchProbe.expect(!game.paused && game.subState == null && !c.NOTE_LEFT && !c.PAUSE, 'resume without stale input/camera');
			case 25:
				TouchProbe.expect(c.NOTE_UP_P && game.keysPressed[2], 'alternative Psych dpad reaches note handler');
			case 29:
				TouchProbe.expect(!game.paused && !c.BACK, 'removed gameplay BACK does nothing');
			case 33:
				var pause:funkin.states.substates.VSlicePauseSubState = cast game.subState;
				TouchProbe.expect(game.paused && pause.inDifficultyMenu, 'C opens difficulty submenu');
				TouchProbe.expect(!c.NOTE_DODGE, 'C must not trigger dodge');
				TouchProbe.expect(pause.entries.length == 3 && pause.entries[0].label == 'Normal' && pause.entries[1].label == 'Hard', 'only bundled Normal/Hard plus Back');
			case 37:
				var pause:funkin.states.substates.VSlicePauseSubState = cast game.subState;
				TouchProbe.expect(!pause.inDifficultyMenu, 'B cancels difficulty choice');
			case 41:
				TouchProbe.expect(!game.paused && game.subState == null, 'B resumes from standard menu');
			case 49:
				var pause:funkin.states.substates.VSlicePauseSubState = cast game.subState;
				TouchProbe.expect(pause.currentEntry == 1, 'down selects Hard');
		}
		if (step > 52 && game != beforeDifficulty && game.generatedMusic && game.startedCountdown)
		{
			TouchProbe.expect(PlayState.storyDifficulty == 2 && !game.paused, 'difficulty selection restarts playable Hard chart');
			Sys.println('GAME TOUCH PASS: notes/holds, V-Slice pause/resume, C difficulty selection/cancel/restart, removed BACK/DODGE and optional Psych dpad');
			Sys.exit(0);
		}
	}
}
