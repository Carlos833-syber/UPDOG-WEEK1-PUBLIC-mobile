package funkin.mobile;

#if android
import flixel.input.keyboard.FlxKey;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.TouchEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;

/** Multi-touch overlay feeding the same keyboard path as physical controls. */
class TouchControls extends Sprite
{
	var buttons:Array<Sprite> = [];
	var labels:Array<TextField> = [];
	var fingers:Map<Int, Int> = [];
	var held:Map<Int, Int> = [];
	var gameplay:Bool = false;
	var lastState:flixel.FlxState;
	var lastSubState:flixel.FlxSubState;
	
	public function new()
	{
		super();
		mouseEnabled = false;
		mouseChildren = false;
		addEventListener(Event.ADDED_TO_STAGE, initialize);
	}
	
	function initialize(_:Event):Void
	{
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
		for (label in ["<", "v", "^", ">", "DODGE", "OK", "BACK"])
		{
			var button = new Sprite();
			var text = new TextField();
			text.defaultTextFormat = new TextFormat("_sans", 22, 0xFFFFFF, true, null, null, "center");
			text.text = label;
			text.selectable = false;
			button.addChild(text);
			addChild(button);
			buttons.push(button);
			labels.push(text);
		}
		stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouch);
		stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouch);
		stage.addEventListener(TouchEvent.TOUCH_END, endTouch);
		stage.addEventListener(Event.DEACTIVATE, releaseAll);
		stage.addEventListener(Event.RESIZE, resize);
		FlxG.signals.preStateSwitch.add(() -> releaseAll(null));
		FlxG.signals.postUpdate.add(refresh);
		resize(null);
	}
	
	function refresh():Void
	{
		var state = FlxG.state;
		var playing = Std.isOfType(state, PlayState) && state.subState == null && !PlayState.instance.paused;
		if (state != lastState || state.subState != lastSubState || playing != gameplay)
		{
			releaseAll(null);
			lastState = state;
			lastSubState = state.subState;
			gameplay = playing;
			labels[5].text = gameplay ? "PAUSE" : "OK";
		}
		visible = !Std.isOfType(state, AndroidBootstrap);
		buttons[4].visible = gameplay;
	}
	
	function resize(_:Event):Void
	{
		releaseAll(null);
		var w = stage.stageWidth;
		var h = stage.stageHeight;
		var size = Math.min(w / 8, h / 5);
		for (i in 0...buttons.length)
		{
			var button = buttons[i];
			button.graphics.clear();
			button.graphics.beginFill(0x182030, 0.6);
			button.graphics.lineStyle(2, 0xFFFFFF, 0.65);
			button.graphics.drawRoundRect(0, 0, size, size, 12);
			button.graphics.endFill();
			button.x = i < 2 ? 12 + i * (size + 8) : i < 4 ? w - (4 - i) * (size + 8) - 4 : w - (7 - i) * (size + 8);
			button.y = i < 4 ? h - size - 12 : 12;
			var fontSize = Std.int(size / 5);
			var format = new TextFormat("_sans", fontSize, 0xFFFFFF, true, null, null, "center");
			labels[i].defaultTextFormat = format;
			labels[i].setTextFormat(format);
			labels[i].width = size;
			labels[i].height = size;
			labels[i].y = (size - fontSize * 1.4) / 2;
		}
	}
	
	function keyFor(button:Int):Int
	{
		var names = gameplay ? ["note_left", "note_down", "note_up", "note_right", "dodge", "pause", "back"] : ["ui_left", "ui_down", "ui_up", "ui_right", "dodge", "accept", "back"];
		var keys = ClientPrefs.keyBinds.get(names[button]);
		if (keys != null) for (key in keys)
			if (key != FlxKey.NONE) return key;
		return -1;
	}
	
	function onTouch(event:TouchEvent):Void
	{
		var key = -1;
		if (visible)
		{
			for (i in 0...buttons.length)
			{
				var button = buttons[i];
				if (button.visible && button.hitTestPoint(event.stageX, event.stageY))
				{
					key = keyFor(i);
					break;
				}
			}
		}
		if (fingers.exists(event.touchPointID) && fingers.get(event.touchPointID) == key) return;
		endTouch(event);
		if (key < 0) return;
		fingers.set(event.touchPointID, key);
		var count = held.exists(key) ? held.get(key) : 0;
		held.set(key, count + 1);
		if (count == 0) sendKey(key, true);
	}
	
	function endTouch(event:TouchEvent):Void
	{
		if (!fingers.exists(event.touchPointID)) return;
		var key = fingers.get(event.touchPointID);
		fingers.remove(event.touchPointID);
		var count = held.get(key) - 1;
		if (count <= 0)
		{
			held.remove(key);
			sendKey(key, false);
		}
		else held.set(key, count);
	}
	
	function releaseAll(_:Event):Void
	{
		for (key in held.keys())
			sendKey(key, false);
		held.clear();
		fingers.clear();
	}
	
	function sendKey(key:Int, down:Bool):Void
	{
		stage.dispatchEvent(new KeyboardEvent(down ? KeyboardEvent.KEY_DOWN : KeyboardEvent.KEY_UP, true, false, 0, key));
	}
}
#end
