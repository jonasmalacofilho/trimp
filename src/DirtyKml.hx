import haxe.io.Output;
import vehjo.Vector;
private typedef L = vehjo.LazyLambda;

class DirtyKml {

	public static function begin( o: Output, name: String, ?radioFolder=false ): Void {
		o.writeString( '<?xml version="1.0" encoding="UTF-8"?>\n' );
		o.writeString( '<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">\n' );
		o.writeString( '<Document><name>' );
		o.writeString( name );
		o.writeString( '</name>\n' );
		if ( radioFolder )
			o.writeString( '\t<Style><ListStyle><listItemType>radioFolder</listItemType></ListStyle></Style>\n' );
	}

	public static function end( o: Output ): Void {
		o.writeString( '</Document>\n' );
		o.writeString( '</kml>\n' );
	}

	public static function beginFolder( o: Output, name: String, ?radioFolder=false ): Void {
		o.writeString( '\t<Folder><name>' );
		o.writeString( name );
		o.writeString( '</name>\n' );
		if ( radioFolder )
			o.writeString( '\t\t<Style><ListStyle><listItemType>radioFolder</listItemType></ListStyle></Style>\n' );
	}

	public static function endFolder( o: Output ): Void {
		o.writeString( '\t</Folder>\n' );
	}

	public static function addPoint( o: Output, name: String, p: Vector, ?color: Null<String>, ?scale: Null<Float>, ?icon: Null<String>, ?label: Null<Float>, ?labelColor: Null<String>, ?visible=true, ?description: Null<String> ) {
		o.writeString( '\t<Placemark>\n\t<name>' );
		o.writeString( name );
		o.writeString( '</name>\n\t<description>' );
		o.writeString( description != null ? description : name );
		o.writeString( '</description>\n' );
		if ( !visible )
			o.writeString( '\t<visibility>0</visibility>\n' );
		if ( color != null || scale != null || icon != null ) {
			o.writeString( '\t\t<Style>\n' );
			if ( color != null || scale != null || icon != null ) {
				o.writeString( '\t\t\t<IconStyle>\n' );
				if ( color != null ) {
					o.writeString( '\t\t\t\t<color>' );
					o.writeString( color );
					o.writeString( '</color>\n' );
				}
				if ( scale != null ) {
					o.writeString( '\t\t\t\t<scale>' );
					o.writeString( Std.string( scale ) );
					o.writeString( '</scale>\n' );
				}
				if ( icon != null ) {
					o.writeString( '\t\t\t\t<Icon><href>' );
					o.writeString( icon );
					o.writeString( '</href></Icon>\n' );
				}
				o.writeString( '\t\t\t</IconStyle>\n' );
			}
			if ( label != null || labelColor != null ) {
				o.writeString( '\t\t\t<LabelStyle>\n' );
				if ( label != null ) {
					o.writeString( '\t\t\t\t<scale>' );
					o.writeString( Std.string( label ) );
					o.writeString( '</scale>\n' );
				}
				if ( labelColor != null ) {
					o.writeString( '\t\t\t\t<color>' );
					o.writeString( color );
					o.writeString( '</color>\n' );
				}
				o.writeString( '\t\t\t</LabelStyle>\n' );
			}
			o.writeString( '\t\t</Style>\n' );
		}
		o.writeString( '\t\t<Point><coordinates>\n' );
		o.writeString( '\t\t\t' + p.x + ',' + p.y + ',0\n' );
		o.writeString( '\t\t</coordinates></Point>\n' );
		o.writeString( '\t</Placemark>\n' );
	}

	public static function addLineString( o: Output, name: String, vs: Iterable<Vector>, ?color: Null<String>, ?width: Null<Float>, ?label: Null<Float>, ?labelColor: Null<String>, ?visible=true, ?description: Null<String> ): Void {
		o.writeString( '\t<Placemark>\n\t<name>' );
		o.writeString( name );
		o.writeString( '</name>\n\t<description>' );
		o.writeString( description != null ? description : name );
		o.writeString( '</description>\n' );
		if ( !visible )
			o.writeString( '\t<visibility>0</visibility>\n' );
		if ( color != null || width != null || label > 0. ) {
			o.writeString( '\t\t<Style>\n' );
			if ( color != null || width != null ) {
				o.writeString( '\t\t\t<LineStyle>\n' );
				if ( color != null ) {
					o.writeString( '\t\t\t\t<color>' );
					o.writeString( color );
					o.writeString( '</color>\n' );
				}
				if ( width != null ) {
					o.writeString( '\t\t\t\t<width>' );
					o.writeString( Std.string( width ) );
					o.writeString( '</width>\n' );
				}
				if ( label != null )
					o.writeString( '\t\t\t\t<gx:labelVisibility>1</gx:labelVisibility>' );
				o.writeString( '\t\t\t</LineStyle>\n' );
			}
			if ( label != null ) {
				o.writeString( '\t\t\t<LabelStyle>\n' );
				o.writeString( '\t\t\t\t<scale>' );
				o.writeString( Std.string( label ) );
				o.writeString( '</scale>\n' );
				if ( labelColor != null ) {
					o.writeString( '\t\t\t\t<color>' );
					o.writeString( color );
					o.writeString( '</color>\n' );
				}
				o.writeString( '\t\t\t</LabelStyle>\n' );
			}
			o.writeString( '\t\t</Style>\n' );
		}
		o.writeString( '\t\t<LineString><tessellate>1</tessellate><coordinates>\n' );
		o.writeString( '\t\t\t' + L.join( L.map( vs, $x.x + ',' + $x.y ), ',0\n\t\t\t' ) + ',0\n' );
		o.writeString( '\t\t</coordinates></LineString>\n' );
		o.writeString( '\t</Placemark>\n' );
	}

}

