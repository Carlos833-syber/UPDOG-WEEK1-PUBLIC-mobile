package funkin.api;

/** No desktop presence side effects in the native gameplay smoke test. */
class DiscordClient
{
	public static var discordPresences:Array<String> = ['Smoke test'];
	public static var isInitialized:Bool = false;
	
	public static function initialize():Void {}
	
	public static function shutdown():Void {}
	
	public static function changePresence(?a:Dynamic, ?b:Dynamic, ?c:Dynamic, ?d:Dynamic, ?e:Dynamic):Void {}
}
