import haxe.Json;
import haxe.Unserializer;

import sys.io.File;

/** Run after `lime update android` to compare extraction IDs with Lime's package. */
class CheckAndroidAssets
{
	static function main()
	{
		var expected:Dynamic = Json.parse(File.getContent(".android/manifest.json"));
		var registered:Map<String, Dynamic> = [];
		for (library in ["default", "videos", "songs"])
		{
			var raw:Dynamic = Json.parse(File.getContent('export/release/android/bin/app/src/main/assets/manifest/$library.json'));
			var assets:Array<Dynamic> = Unserializer.run(raw.assets);
			for (asset in assets)
				registered.set((library == "default" ? "" : library + ":") + asset.id, asset);
		}
		var entries:Array<Dynamic> = expected.files;
		var errors = 0;
		for (entry in entries)
		{
			var asset = registered.get(entry.id);
			if (asset == null || asset.size != entry.size || asset.className != null)
			{
				Sys.println('Missing, mismatched or embedded extraction asset: ${entry.id}');
				errors++;
			}
		}
		Sys.println('Checked ${entries.length} extraction assets; $errors errors.');
		Sys.exit(errors == 0 ? 0 : 1);
	}
}
