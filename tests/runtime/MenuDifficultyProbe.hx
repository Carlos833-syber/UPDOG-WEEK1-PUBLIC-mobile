import flixel.FlxG;

import funkin.states.FreeplayState;
import funkin.states.StoryMenuState;

import openfl.events.TouchEvent;

/** Check C on actual music-selection screens, including no repeat while held. */
class MenuDifficultyProbe
{
	var frame = 0;
	var story = false;
	
	public function new()
	{
		FreeplayState.curDiff = 1;
		StoryMenuState.curDiff = 1;
		FlxG.signals.preUpdate.add(inject);
		FlxG.signals.postUpdate.add(check);
	}
	
	function inject():Void
	{
		if (!isTargetState()) return;
		frame++;
		if (frame == 5) TouchProbe.send(TouchEvent.TOUCH_BEGIN, 40, 940, 630);
		if (frame == 8) TouchProbe.send(TouchEvent.TOUCH_END, 40, 940, 630);
		if (frame == 10) TouchProbe.send(TouchEvent.TOUCH_BEGIN, 41, 940, 630);
		if (frame == 11) TouchProbe.send(TouchEvent.TOUCH_END, 41, 940, 630);
	}
	
	function check():Void
	{
		if (!isTargetState()) return;
		var difficulty = story ? StoryMenuState.curDiff : FreeplayState.curDiff;
		if (frame == 5 || frame == 7) TouchProbe.expect(difficulty == 2, 'C selects Hard without repeating while held (story=$story, frame=$frame, difficulty=$difficulty)');
		if (frame == 10) TouchProbe.expect(difficulty == 1, 'C cycles back to Normal');
		if (frame == 15)
		{
			if (!story)
			{
				story = true;
				frame = 0;
				FlxG.switchState(() -> new StoryMenuState());
			}
			else
			{
				Sys.println('MENU DIFFICULTY PASS: C toggles Normal/Hard once per touch in Freeplay and Story');
				Sys.exit(0);
			}
		}
	}
	
	function isTargetState():Bool
	{
		if (FlxG.state.subState != null) return false;
		return story ? Std.isOfType(FlxG.state, StoryMenuState) : Std.isOfType(FlxG.state, FreeplayState);
	}
}
