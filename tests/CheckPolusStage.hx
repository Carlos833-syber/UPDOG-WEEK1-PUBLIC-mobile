import crowplexus.hscript.Parser;
import crowplexus.hscript.Interp;

class Point
{
	public var x:Float = 0;
	public var y:Float = 0;
	
	public function new() {}
	
	public function set(x:Float, y:Float):Void
	{
		this.x = x;
		this.y = y;
	}
}

class DummySprite
{
	public var alpha:Float = 1;
	public var y:Float = 0;
	public var zIndex:Int = 0;
	public var scale = new Point();
	public var scrollFactor = new Point();
	public var cameras:Array<Dynamic> = [];
	public var animation:Dynamic =
		{
			addByPrefix: function(a:String, b:String, c:Int, d:Bool) {
			}
		};
		
	public function new(?a:Dynamic, ?x:Float, ?y:Float) {}
	
	public function loadSparrowFrames(s:String):DummySprite
	{
		return this;
	}
}

/** Exercises stage startup logic without allocating game textures. */
class CheckPolusStage
{
	static function main()
	{
		var source = sys.io.File.getContent(Sys.args()[0]);
		var start = source.indexOf('function onCreatePost()');
		var end = source.indexOf('function revealVoters()');
		if (start < 0 || end <= start) throw 'Stage startup functions not found';
		var body = source.substring(start, end);
		for (song in ['Sussus Moogus', 'Sabotage', 'Meltdown'])
			for (low in [false, true])
			{
				var i = new Interp();
				var p = new Parser();
				p.allowTypes = true;
				var camera:Dynamic = {zoom: 1.0, alpha: 1.0, scroll: {x: 0.0, y: 0.0}};
				var camList:Array<Dynamic> = [];
				var game:Dynamic =
					{
						camHUD: camera,
						camGame: camera,
						camPause: camera,
						isCameraOnForcedPos: false,
						snapCamFollowToPos: function(x:Int, y:Int) {
						}
					};
				for (name in ['dadGroup', 'gfGroup', 'boyfriendGroup', 'gf', 'gfDead', 'boomBox', 'cyan', 'rose', 'nigga'])
					i.variables.set(name, new DummySprite());
				for (name in ['evilGreen', 'vignette2', 'anotherCam', 'evilCam'])
					i.variables.set(name, null);
				i.variables.set('PlayState', {SONG: {song: song}});
				i.variables.set('songName', song);
				i.variables.set('game', game);
				i.variables.set('ext', 'stage/polus/');
				i.variables.set('snowAlpha', 0);
				i.variables.set('ClientPrefs', {lowQuality: low});
				i.variables.set('BGSprite', DummySprite);
				i.variables.set('CameraUtil',
					{
						quickCreateCam: function(b:Bool):Dynamic {
							return {zoom: 1.0, scroll: {x: 0.0, y: 0.0}};
						}
					});
				i.variables.set('FlxG',
					{
						camera: camera,
						cameras:
							{
								list: camList,
								insert: function(c:Dynamic, n:Int, b:Bool) {
									camList.push(c);
								}
							}
					});
				i.variables.set('add', function(v:Dynamic) {
				});
				i.variables.set('refreshZ', function() {
				});
				i.execute(p.parseString(body));
				Reflect.callMethod(null, i.variables.get('onCreatePost'), []);
				Reflect.callMethod(null, i.variables.get('onUpdate'), [0.016]);
				if (i.variables.get('anotherCam') == null) throw 'camera missing';
				Sys.println('PASS ' + song + ' lowQuality=' + low + ' init+update');
			}
	}
}
