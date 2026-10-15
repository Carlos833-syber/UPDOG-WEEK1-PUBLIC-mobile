import flixel.FlxG;
import flixel.FlxState;

import funkin.backend.PlayerSettings;
import funkin.mobile.TouchControls;

import openfl.events.TouchEvent;

/** Sends real OpenFL touch events through FlxTouchManager and the production plugin. */
class TouchProbe extends FlxState
{
	var frame = 0;
	
	public static function send(type:String, id:Int, x:Float, y:Float):Void
	{
		// Tests also run at 960x540, so convert virtual game coordinates to the window.
		FlxG.stage.dispatchEvent(new TouchEvent(type, true, false, id, false, x * FlxG.scaleMode.scale.x + FlxG.scaleMode.offset.x, y * FlxG.scaleMode.scale.y + FlxG.scaleMode.offset.y));
	}
	
	public static function expect(value:Bool, message:String):Void
	{
		if (!value) throw 'Touch regression: $message';
	}
	
	override function create():Void
	{
		super.create();
		persistentUpdate = true;
		FlxG.signals.preUpdate.add(inject);
	}
	
	function inject():Void
	{
		frame++;
		switch (frame)
		{
			case 3:
				send(TouchEvent.TOUCH_BEGIN, 10, 1200, 630);
			case 5:
				send(TouchEvent.TOUCH_END, 10, 1200, 630);
			case 7:
				send(TouchEvent.TOUCH_BEGIN, 11, 40, 520);
				send(TouchEvent.TOUCH_BEGIN, 12, 150, 400);
			case 9:
				send(TouchEvent.TOUCH_END, 11, 40, 520);
			case 10:
				send(TouchEvent.TOUCH_END, 12, 150, 400);
			case 12:
				send(TouchEvent.TOUCH_BEGIN, 13, 150, 630);
				send(TouchEvent.TOUCH_BEGIN, 14, 155, 635);
			case 14:
				send(TouchEvent.TOUCH_END, 13, 150, 630);
			case 16:
				send(TouchEvent.TOUCH_END, 14, 155, 635);
			case 18:
				send(TouchEvent.TOUCH_BEGIN, 15, 150, 630);
			case 19:
				send(TouchEvent.TOUCH_MOVE, 15, 270, 520);
			case 20:
				send(TouchEvent.TOUCH_END, 15, 270, 520);
			case 22:
				send(TouchEvent.TOUCH_BEGIN, 16, 40, 520);
			case 23:
				openSubState(new flixel.FlxSubState());
			case 24:
				send(TouchEvent.TOUCH_END, 16, 40, 520);
			case 26:
				closeSubState();
		}
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		var c = PlayerSettings.player1.controls;
		switch (frame)
		{
			case 3:
				expect(c.ACCEPT, 'A -> confirm on first frame');
			case 4:
				expect(!c.ACCEPT, 'held A must not repeat confirm');
			case 7:
				expect(c.UI_LEFT_P && c.UI_UP_P, 'simultaneous left/up');
			case 8:
				expect(c.UI_LEFT && c.UI_UP && !c.UI_LEFT_P, 'hold without repeated edge');
			case 9:
				expect(c.UI_LEFT_R && !c.UI_LEFT && c.UI_UP, 'independent release');
			case 12:
				expect(c.UI_DOWN_P, 'two fingers on one button');
			case 14:
				expect(c.UI_DOWN && !c.UI_DOWN_R, 'first release must not release second finger');
			case 16:
				expect(c.UI_DOWN_R, 'last finger releases button');
			case 19:
				expect(c.UI_DOWN_R && c.UI_RIGHT_P, 'swipe between buttons');
			case 24:
				expect(!c.UI_LEFT, 'opening substate clears held input');
			case 28:
				Sys.println('TOUCH PASS: native events, menu confirm, multi-touch, hold/release, swipe and substate reset');
				Sys.exit(0);
		}
	}
}
