// Adapted from Psych-Engine-0.7.3-Mobile (StarNova / Cream.BR).
// See NOTICE.md. Four touch lanes with a short color flash on each press.
package funkin.mobile.psych;

class MobileHitbox extends TouchInputManager
{
	public function new()
	{
		super();
		var colors = [0xFF00FF, 0x00FFFF, 0x00FF00, 0xFF0000];
		var ids = [TouchInputID.NOTE_LEFT, TouchInputID.NOTE_DOWN, TouchInputID.NOTE_UP, TouchInputID.NOTE_RIGHT];
		for (i in 0...4)
		{
			var width = FlxG.width / 4;
			var hint = new TouchButton(i * width, 100, [ids[i]]);
			// A shared 1px graphic avoids allocating four screen-sized bitmaps.
			hint.makeGraphic(1, 1, FlxColor.WHITE);
			hint.scale.set(width, FlxG.height - 100);
			hint.updateHitbox();
			hint.color = colors[i];
			hint.alpha = 0.00001;
			hint.solid = hint.moves = false;
			hint.immovable = true;
			hint.scrollFactor.set();
			add(hint);
		}
		scrollFactor.set();
		refreshMappedButtons();
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		for (button in members)
		{
			var target = ClientPrefs.mobileShowHitboxes && button.pressed ? 0.2 : 0.00001;
			button.alpha += (target - button.alpha) * Math.min(1, elapsed / 0.075);
		}
	}
}
