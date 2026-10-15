package funkin.mobile;

#if android
import flixel.FlxState;
import flixel.ui.FlxButton;

import openfl.desktop.Clipboard;
import openfl.desktop.ClipboardFormats;

/** A small error screen that still works when a game texture failed to load. */
class AndroidCrashState extends FlxState
{
	var report:String;
	
	public function new(report:String)
	{
		super();
		this.report = report;
	}
	
	override function create():Void
	{
		super.create();
		bgColor = FlxColor.BLACK;
		FlxG.sound.music?.stop();
		var title = new FlxText(24, 20, FlxG.width - 48, 'Erro ao executar o jogo', 28);
		add(title);
		var text = new FlxText(24, 70, FlxG.width - 48, report.split('\n').slice(0, 23).join('\n'), 18);
		add(text);
		var copy = new FlxButton(FlxG.width / 2 - 80, FlxG.height - 140, 'Copiar erro', () -> {
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, report);
		});
		copy.scale.set(2, 2);
		copy.updateHitbox();
		add(copy);
	}
}
#end
