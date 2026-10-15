import flixel.FlxG;

import funkin.data.ClientPrefs;
import funkin.modchart.modifiers.TransformModifier;
import funkin.states.PlayState;

/** Checks the actual update path that previously overwrote the centered layout. */
@:access(funkin.states.PlayState)
class MiddlescrollProbe
{
	var frames = 0;
	var tapNotesChecked = 0;
	var transformed = false;
	var playerX = [414.0, 526, 638, 750];
	var opponentX = [78.0, 190, 974, 1086];
	
	public function new()
	{
		FlxG.signals.postUpdate.add(check);
	}
	
	function near(actual:Float, expected:Float, label:String):Void
	{
		if (Math.abs(actual - expected) > 0.01) throw '$label: expected $expected, got $actual';
	}
	
	function check():Void
	{
		if (!Std.isOfType(FlxG.state, PlayState)) return;
		var game:PlayState = cast FlxG.state;
		if (!game.startedCountdown || !game.generatedMusic) return;
		frames++;
		
		for (lane in 0...4)
		{
			near(game.playerStrums.members[lane].x, playerX[lane] + (transformed ? 37 : 0), 'centered player receptor $lane');
			near(game.opponentStrums.members[lane].x, opponentX[lane], 'split opponent receptor $lane');
		}
		
		for (note in game.notes.members)
		{
			if (note == null || !note.alive || note.isSustainNote) continue;
			var expected = note.lane == 0 ? playerX[note.noteData] + (transformed ? 37 : 0) : opponentX[note.noteData];
			near(note.x, expected + note.offsetX + game.script_NOTEOffsets[note.noteData].x, 'incoming tap note uses receptor layout');
			tapNotesChecked++;
		}
		
		switch (frames)
		{
			case 5:
				// The preference must leave the original side layout and extra fields unchanged.
				var extraX = game.modManager.getBaseX(0, 2);
				ClientPrefs.middleScroll = false;
				for (lane in 0...4)
				{
					near(game.modManager.getBaseX(lane, 0), 734 + 112 * lane, 'normal player baseline');
					near(game.modManager.getBaseX(lane, 1), 102 + 112 * lane, 'normal opponent baseline');
				}
				near(game.modManager.getBaseX(0, 2), extraX, 'extra field baseline');
				ClientPrefs.middleScroll = true;
				// Run a real modifier after the baseline to guard against a post-modchart snap.
				game.modManager.quickRegister(new TransformModifier(game.modManager));
				game.modManager.setValue('transformX', 37, 0);
				transformed = true;
			case 20:
				game.modManager.setValue('transformX', 0, 0);
				transformed = false;
			case 240:
				if (tapNotesChecked == 0) throw 'No incoming tap notes were checked';
				Sys.println('MIDDLESCROLL PASS: centered player, split opponent, incoming notes, original side layout and live transform modifier');
				Sys.exit(0);
		}
	}
}
