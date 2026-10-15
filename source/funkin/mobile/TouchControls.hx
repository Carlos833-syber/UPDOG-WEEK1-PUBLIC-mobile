package funkin.mobile;

#if MOBILE_CONTROLS
import flixel.input.FlxInput.FlxInputState;

import funkin.mobile.psych.MobileHitbox;
import funkin.mobile.psych.MobileVirtualPad;
import funkin.mobile.psych.TouchButton;
import funkin.mobile.psych.TouchInputID;
import funkin.mobile.psych.TouchInputManager;

/** Psych mobile controls, polled before the active state rather than emulating keys. */
class TouchControls extends FlxBasic
{
	public static var instance(default, null):TouchControls;
	
	var pad:MobileVirtualPad;
	var hitbox:MobileHitbox;
	var actions:TouchInputManager;
	
	public var touchCamera(default, null):FlxCamera;
	
	var lastState:flixel.FlxState;
	var lastSubState:flixel.FlxSubState;
	var gameplay:Bool = false;
	var fourLanes:Bool = false;
	var waitingForRelease:Bool = false;
	
	public static function install():Void
	{
		if (instance == null) FlxG.plugins.add(instance = new TouchControls());
	}
	
	public function new()
	{
		super();
		FlxG.signals.preStateSwitch.add(reset);
		FlxG.signals.postStateSwitch.add(refresh);
		FlxG.signals.focusLost.add(reset);
		FlxG.signals.gameResized.add(onResize);
	}
	
	function onResize(w:Int, h:Int):Void
	{
		lastState = null;
	}
	
	function reset():Void
	{
		for (group in [cast pad, cast hitbox, actions])
			if (group != null) for (button in group.members)
				button.resetInput();
		waitingForRelease = true;
	}
	
	function refresh():Void
	{
		var state = FlxG.state;
		var playing = Std.isOfType(state, PlayState) && state.subState == null && !PlayState.instance.paused;
		if (state == lastState
			&& state.subState == lastSubState
			&& playing == gameplay
			&& fourLanes == ClientPrefs.mobileFourLaneHitbox) return;
		reset();
		lastState = state;
		lastSubState = state.subState;
		gameplay = playing;
		fourLanes = ClientPrefs.mobileFourLaneHitbox;
		if (pad != null) pad.destroy();
		if (hitbox != null) hitbox.destroy();
		if (actions != null) actions.destroy();
		if (touchCamera != null && FlxG.cameras.list.contains(touchCamera)) FlxG.cameras.remove(touchCamera);
		touchCamera = new FlxCamera();
		touchCamera.bgColor = 0;
		FlxG.cameras.add(touchCamera, false);
		var difficultyMenu = state.subState == null && (Std.isOfType(state, FreeplayState) || Std.isOfType(state, StoryMenuState));
		pad = new MobileVirtualPad(!gameplay || !fourLanes, !gameplay, difficultyMenu);
		hitbox = new MobileHitbox();
		actions = new TouchInputManager();
		if (gameplay)
		{
			addAction(FlxG.width - 180, 'PAUSE', A);
			addAction(0, 'C', C);
		}
		actions.refreshMappedButtons();
		for (group in [pad, hitbox, actions])
			group.cameras = [touchCamera];
	}
	
	function addAction(x:Float, label:String, id:TouchInputID):Void
	{
		var button = new TouchButton(x, 0, [id], label);
		if (label == 'PAUSE')
		{
			button.x = FlxG.width - 100;
			button.makeGraphic(90, 90, FlxColor.TRANSPARENT, true);
			flixel.util.FlxSpriteUtil.drawCircle(button, 45, 45, 43, 0xCC202020);
			flixel.util.FlxSpriteUtil.drawRect(button, 29, 23, 11, 44, FlxColor.WHITE);
			flixel.util.FlxSpriteUtil.drawRect(button, 50, 23, 11, 44, FlxColor.WHITE);
			button.text = '';
		}
		else
		{
			button.makeGraphic(170, 90, 0xCC202020);
			button.label.setFormat(Paths.font('vcr.ttf'), 25, FlxColor.WHITE, CENTER);
		}
		button.alpha = 0.7;
		actions.add(button);
	}
	
	override public function update(elapsed:Float):Void
	{
		refresh();
		if (waitingForRelease)
		{
			// A held menu-confirm finger must not become a note or pause press.
			for (touch in FlxG.touches.list)
				if (touch.pressed) return;
			waitingForRelease = false;
		}
		if (gameplay)
		{
			if (fourLanes) hitbox.update(elapsed);
			else pad.update(elapsed);
			actions.update(elapsed);
		}
		else pad.update(elapsed);
	}
	
	override public function draw():Void
	{
		if (touchCamera == null) return;
		if (!gameplay || !fourLanes) pad.draw();
		else hitbox.draw();
		if (gameplay) actions.draw();
	}
	
	static final noteActions = ['note_left', 'note_down', 'note_up', 'note_right'];
	
	public static function noteEdge(lane:Int, released:Bool):Bool
	{
		return check(noteActions[lane] + (released ? '-release' : '-press'));
	}
	
	public static function check(action:String):Bool
	{
		var self = instance;
		if (self == null || self.pad == null || self.waitingForRelease) return false;
		var state:FlxInputState = PRESSED;
		var name = action;
		if (action.endsWith('-press'))
		{
			name = action.substr(0, action.length - 6);
			state = JUST_PRESSED;
		}
		else if (action.endsWith('-release'))
		{
			name = action.substr(0, action.length - 8);
			state = JUST_RELEASED;
		}
		var id:TouchInputID = switch (name)
		{
			case 'ui_left': LEFT;
			case 'ui_down': DOWN;
			case 'ui_up': UP;
			case 'ui_right': RIGHT;
			case 'note_left': self.fourLanes ? NOTE_LEFT : LEFT;
			case 'note_down': self.fourLanes ? NOTE_DOWN : DOWN;
			case 'note_up': self.fourLanes ? NOTE_UP : UP;
			case 'note_right': self.fourLanes ? NOTE_RIGHT : RIGHT;
			case 'accept', 'pause': A;
			case 'back': B;
			case 'difficulty': C;
			default: NONE;
		};
		if (name == 'accept' || name == 'back' || name == 'pause' || name == 'difficulty') state = JUST_PRESSED;
		var group:TouchInputManager = self.gameplay ? (name.startsWith('note_')
			&& name != 'note_dodge' ? (self.fourLanes ? self.hitbox : self.pad) : self.actions) : self.pad;
		// Gameplay actions must not leak into menu/note bindings and vice versa.
		if (self.gameplay && (name.startsWith('ui_') || name == 'accept')) return false;
		if (!self.gameplay && (name.startsWith('note_') || name == 'pause')) return false;
		return switch (state)
		{
			case JUST_PRESSED: group.isJustPressed(id);
			case JUST_RELEASED: group.isJustReleased(id);
			default: group.isPressed(id);
		};
	}
	
	override public function destroy():Void
	{
		FlxG.signals.preStateSwitch.remove(reset);
		FlxG.signals.postStateSwitch.remove(refresh);
		FlxG.signals.focusLost.remove(reset);
		FlxG.signals.gameResized.remove(onResize);
		reset();
		if (pad != null) pad.destroy();
		if (hitbox != null) hitbox.destroy();
		if (actions != null) actions.destroy();
		if (touchCamera != null && FlxG.cameras.list.contains(touchCamera)) FlxG.cameras.remove(touchCamera);
		instance = null;
		super.destroy();
	}
}
#end
