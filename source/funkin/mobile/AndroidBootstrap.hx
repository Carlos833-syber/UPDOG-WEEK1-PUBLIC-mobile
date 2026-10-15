package funkin.mobile;

#if android
import flixel.FlxState;

import haxe.Json;
import haxe.io.Path;

import lime.system.System;
import lime.utils.Assets;

import sys.FileSystem;
import sys.io.File;

/** Materialize packaged assets before any state uses sys.io or native video paths. */
class AndroidBootstrap extends FlxState
{
	var files:Array<AndroidAsset>;
	var previous:Map<String, String> = [];
	var manifestText:String;
	var root:String;
	var index:Int = 0;
	var failed:Bool = false;
	var progress:FlxText;
	
	override function create():Void
	{
		super.create();
		progress = new FlxText(40, FlxG.height / 2, FlxG.width - 80, "Preparing game files…", 24);
		progress.alignment = CENTER;
		add(progress);
		try
		{
			root = Path.join([System.applicationStorageDirectory, "game"]);
			FileSystem.createDirectory(root);
			manifestText = Assets.getText("android-manifest.json");
			var manifest:AndroidManifest = Json.parse(manifestText);
			files = manifest.files;
			var marker = Path.join([root, ".assets.json"]);
			if (FileSystem.exists(marker))
			{
				try
				{
					var old:AndroidManifest = Json.parse(File.getContent(marker));
					for (entry in old.files)
						previous.set(entry.path, entry.sha256);
				}
				catch (_:Dynamic)
					previous.clear();
			}
		}
		catch (error:Dynamic)
			fail(error);
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (failed) return;
		try
		{
			var start = haxe.Timer.stamp();
			while (index < files.length && haxe.Timer.stamp() - start < 0.02)
			{
				var entry = files[index++];
				var destination = Path.join([root, entry.path]);
				if (previous.get(entry.path) == entry.sha256
					&& FileSystem.exists(destination)
					&& FileSystem.stat(destination).size == entry.size) continue;
				var bytes = Assets.getBytes(entry.id);
				if (bytes == null || bytes.length != entry.size) throw 'Missing or damaged asset: ${entry.id}';
				FileSystem.createDirectory(Path.directory(destination));
				File.saveBytes(destination + ".tmp", bytes);
				FileSystem.rename(destination + ".tmp", destination);
			}
			progress.text = 'Preparing game files: $index / ${files.length}';
			if (index == files.length)
			{
				// Remove only files owned by an earlier package, never saves or user files.
				var current = [for (entry in files) entry.path => true];
				for (path in previous.keys())
				{
					if (!current.exists(path) && (path.startsWith("assets/") || path.startsWith("content/")) && !path.contains(".."))
					{
						var old = Path.join([root, path]);
						if (FileSystem.exists(old) && !FileSystem.isDirectory(old)) FileSystem.deleteFile(old);
					}
				}
				File.saveContent(Path.join([root, ".assets.json.tmp"]), manifestText);
				FileSystem.rename(Path.join([root, ".assets.json.tmp"]), Path.join([root, ".assets.json"]));
				Sys.setCwd(root);
				FlxG.switchState(() -> new Splash());
			}
		}
		catch (error:Dynamic)
			fail(error);
	}
	
	function fail(error:Dynamic):Void
	{
		failed = true;
		progress.text = 'Unable to prepare game files. Check free storage and restart.\n$error';
	}
}

private typedef AndroidAsset =
{
	var path:String;
	var id:String;
	var sha256:String;
	var size:Int;
}

private typedef AndroidManifest =
{
	var version:String;
	var files:Array<AndroidAsset>;
}
#end
