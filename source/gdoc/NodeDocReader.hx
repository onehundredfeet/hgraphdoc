package gdoc;
import sys.io.File;
using StringTools;
using Lambda;
import haxe.Json;
class NodeDocReader {

    public static function loadPath( path : String ) : NodeDoc {

        try {
            if (path.toLowerCase().endsWith(".vdx")) {
                return VisioImport.loadAsGraphDoc( path );
            }
            if (path.toLowerCase().endsWith(".json")) {
                return Json.parse(File.getContent(path));
            }
        }
        catch(e) {
            return null;
        }

        return null;
    }
}