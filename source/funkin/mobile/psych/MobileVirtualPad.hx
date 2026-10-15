// Adapted from Psych-Engine-0.7.3-Mobile (StarNova / Cream.BR).
// See NOTICE.md. Layout and three-frame button artwork follow that port.
package funkin.mobile.psych;

import flixel.graphics.frames.FlxTileFrames;

class MobileVirtualPad extends TouchInputManager
{
	public function new(directions:Bool = true, actionButtons:Bool = true)
	{
		super();
		if (directions)
		{
			addButton(105, FlxG.height - 345, 'up', 0x00FF00, UP);
			addButton(0, FlxG.height - 243, 'left', 0xFF00FF, LEFT);
			addButton(207, FlxG.height - 243, 'right', 0xFF0000, RIGHT);
			addButton(105, FlxG.height - 135, 'down', 0x00FFFF, DOWN);
		}
		if (actionButtons)
		{
			addButton(FlxG.width - 258, FlxG.height - 135, 'b', 0xFFCB00, B);
			addButton(FlxG.width - 132, FlxG.height - 135, 'a', 0xFF0000, A);
		}
		scrollFactor.set();
		refreshMappedButtons();
	}
	
	function addButton(x:Float, y:Float, name:String, color:Int, id:TouchInputID):Void
	{
		var graphic = FlxG.bitmap.add('assets/mobile/virtualpad/$name.png');
		var button = new TouchButton(x, y, [id]);
		button.frames = FlxTileFrames.fromGraphic(graphic, FlxPoint.weak(Std.int(graphic.width / 3), graphic.height));
		button.solid = button.moves = false;
		button.immovable = true;
		button.scrollFactor.set();
		button.color = color;
		button.alpha = 0.5;
		add(button);
	}
}
