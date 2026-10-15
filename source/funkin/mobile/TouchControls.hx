package funkin.mobile;

#if android
import flixel.input.keyboard.FlxKey;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.TouchEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;

/** Multi-touch overlay feeding the same keyboard path as physical controls. */
class TouchControls extends Sprite
{
	var buttons:Array<Sprite> = [];
	var labels:Array<TextField> = [];
	var bounds:Array<Rectangle> = [];
	var fourLanes:Bool = false;
	var showHitboxes:Bool = true;
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
		for (label in ["<", "v", "^", ">", "DODGE", "A", "B"])
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
			bounds.push(new Rectangle());
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
		if (state != lastState
			|| state.subState != lastSubState
			|| playing != gameplay
			|| fourLanes != ClientPrefs.mobileFourLaneHitbox
			|| showHitboxes != ClientPrefs.mobileShowHitboxes)
		{
			releaseAll(null);
			lastState = state;
			lastSubState = state.subState;
			gameplay = playing;
			fourLanes = ClientPrefs.mobileFourLaneHitbox;
			showHitboxes = ClientPrefs.mobileShowHitboxes;
			labels[5].text = gameplay ? "PAUSE" : "A";
			labels[6].text = gameplay ? "BACK" : "B";
			resize(null);
		}
		visible = !Std.isOfType(state, AndroidBootstrap);
		buttons[4].visible = gameplay;
		for (i in 0...buttons.length)
		{
			var pressed = held.exists(keyFor(i));
			buttons[i].alpha = gameplay && i < 4 && fourLanes ? (showHitboxes ? (pressed ? 0.45 : 0.12) : 0) : (pressed ? 1 : 0.65);
		}
	}
	
	function resize(_:Event):Void
	{
		releaseAll(null);
		var w = stage.stageWidth;
		var h = stage.stageHeight;
		var size = Math.min(w / 8, h / 5);
		var gap = 8.0;
		var padX = 12.0;
		var padY = h - 2 * size - gap - 12;
		var colors = [0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F];
		for (i in 0...buttons.length)
		{
			var button = buttons[i];
			var lane = gameplay && fourLanes && i < 4;
			var width = lane ? w / 4 : size;
			var height = lane ? h : size;
			if (lane)
			{
				button.x = i * width;
				button.y = 0;
			}
			else if (i < 4)
			{
				// A directional pad at the left, with up above down.
				button.x = padX + (i == 0 ? 0 : i == 3 ? 2 : 1) * (size + gap);
				button.y = padY + (i == 2 ? 0 : size + gap);
			}
			else
			{
				button.x = w - (7 - i) * (size + gap) - 12;
				button.y = gameplay ? 12 : h - size - 12 - (i == 5 ? size * 0.6 : 0);
			}
			bounds[i].setTo(button.x, button.y, width, height);
			button.graphics.clear();
			button.graphics.beginFill(i < 4 ? colors[i] : i == 5 ? 0x12FA05 : 0xF9393F);
			button.graphics.lineStyle(2, 0xFFFFFF, 0.8);
			if (lane) button.graphics.drawRect(0, 0, width, height);
			else button.graphics.drawRoundRect(0, 0, width, height, 12);
			button.graphics.endFill();
			var fontSize = Std.int(size / (i < 4 || !gameplay ? 2 : 5));
			var format = new TextFormat("_sans", fontSize, 0xFFFFFF, true, null, null, "center");
			labels[i].defaultTextFormat = format;
			labels[i].setTextFormat(format);
			labels[i].width = width;
			labels[i].height = size;
			labels[i].y = lane ? height - size : (size - fontSize * 1.4) / 2;
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
			// Action buttons take priority over the full-height note lanes.
			for (offset in 0...buttons.length)
			{
				var i = buttons.length - 1 - offset;
				var button = buttons[i];
				if (button.visible && bounds[i].contains(event.stageX, event.stageY))
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
