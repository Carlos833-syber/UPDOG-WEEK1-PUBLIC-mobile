package funkin.objects.video;

/** Desktop smoke test only: fail explicitly if a tested path requests native video. */
class FunkinVideoSprite extends flixel.FlxSprite
{
	public static var _videos:Array<FunkinVideoSprite> = [];
	public static var MUTED:String = '';
	public static var LOOPING:String = '';
	
	public var bitmap:Dynamic;
	public var wasPlaying:Bool = false;
	public var onReady = new flixel.util.FlxSignal();
	public var onFinish = new flixel.util.FlxSignal();
	
	public static function init():Void {}
	
	public function load(path:Dynamic):Bool
	{
		throw 'Video is outside this smoke test: $path';
	}
	
	public function preload(path:Dynamic, ?options:Array<String>):FunkinVideoSprite
	{
		load(path);
		return this;
	}
	
	public function playVideo():Void
	{
		throw 'Video is outside this smoke test';
	}
	
	public function pause():Void {}
	
	public function resume():Void {}
}
