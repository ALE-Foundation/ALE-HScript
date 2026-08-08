package;

typedef Harmony =
{
	original:FlxColor,
	warmer:FlxColor,
	colder:FlxColor
}

typedef TriadicHarmony =
{
	color1:FlxColor,
	color2:FlxColor,
	color3:FlxColor
}

abstract FlxColor(Int) from Int from UInt to Int to UInt
{
	public static inline var TRANSPARENT:FlxColor = 0x00000000;
	public static inline var WHITE:FlxColor = 0xFFFFFFFF;
	public static inline var GRAY:FlxColor = 0xFF808080;
	public static inline var BLACK:FlxColor = 0xFF000000;

	public static inline var GREEN:FlxColor = 0xFF008000;
	public static inline var LIME:FlxColor = 0xFF00FF00;
	public static inline var YELLOW:FlxColor = 0xFFFFFF00;
	public static inline var ORANGE:FlxColor = 0xFFFFA500;
	public static inline var RED:FlxColor = 0xFFFF0000;
	public static inline var PURPLE:FlxColor = 0xFF800080;
	public static inline var BLUE:FlxColor = 0xFF0000FF;
	public static inline var BROWN:FlxColor = 0xFF8B4513;
	public static inline var PINK:FlxColor = 0xFFFFC0CB;
	public static inline var MAGENTA:FlxColor = 0xFFFF00FF;
	public static inline var CYAN:FlxColor = 0xFF00FFFF;

	public var red(get, set):Int;
	public var blue(get, set):Int;
	public var green(get, set):Int;
	public var alpha(get, set):Int;

	public var redFloat(get, set):Float;
	public var blueFloat(get, set):Float;
	public var greenFloat(get, set):Float;
	public var alphaFloat(get, set):Float;

	public var cyan(get, set):Float;
	public var magenta(get, set):Float;
	public var yellow(get, set):Float;
	public var black(get, set):Float;

	public var rgb(get, set):FlxColor;

	public var hue(get, set):Float;

	public var saturation(get, set):Float;

	public var brightness(get, set):Float;

	public var lightness(get, set):Float;

	public var luminance(get, never):Float;

	static var COLOR_REGEX = ~/^(0x|#)(([A-F0-9]{2}){3,4})$/i;

	public static inline function fromInt(Value:Int):FlxColor
	{
		return new FlxColor(Value);
	}

	public static inline function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
	{
		var color = new FlxColor();
		return color.setRGB(Red, Green, Blue, Alpha);
	}

	public static inline function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setRGBFloat(Red, Green, Blue, Alpha);
	}

	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

	public static function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setHSB(Hue, Saturation, Brightness, Alpha);
	}

	public static inline function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setHSL(Hue, Saturation, Lightness, Alpha);
	}

	public static function getHSBColorWheel(Alpha:Int = 255):Array<FlxColor>
		return [for (c in 0...360) fromHSB(c, 1.0, 1.0, Alpha)];

	public static inline function interpolate(Color1:FlxColor, Color2:FlxColor, Factor:Float = 0.5):FlxColor
	{
		var r:Int = Std.int((Color2.red - Color1.red) * Factor + Color1.red);
		var g:Int = Std.int((Color2.green - Color1.green) * Factor + Color1.green);
		var b:Int = Std.int((Color2.blue - Color1.blue) * Factor + Color1.blue);
		var a:Int = Std.int((Color2.alpha - Color1.alpha) * Factor + Color1.alpha);

		return fromRGB(r, g, b, a);
	}

	@:op(A * B)
	public static inline function multiply(lhs:FlxColor, rhs:FlxColor):FlxColor
		return FlxColor.fromRGBFloat(lhs.redFloat * rhs.redFloat, lhs.greenFloat * rhs.greenFloat, lhs.blueFloat * rhs.blueFloat);

	@:op(A + B)
	public static inline function add(lhs:FlxColor, rhs:FlxColor):FlxColor
		return FlxColor.fromRGB(lhs.red + rhs.red, lhs.green + rhs.green, lhs.blue + rhs.blue);

	@:op(A - B)
	public static inline function subtract(lhs:FlxColor, rhs:FlxColor):FlxColor
		return FlxColor.fromRGB(lhs.red - rhs.red, lhs.green - rhs.green, lhs.blue - rhs.blue);
	
	public function getDistance(color:FlxColor)
	{
		inline function abs(n:Int):Int
			return n < 0 ? -n : n;
		
		return abs(color.red - red)
			+ abs(color.green - green)
			+ abs(color.blue - blue)
			+ abs(color.alpha - alpha);
	}
	
	overload public inline extern function nearest(colors:Array<FlxColor>):Null<FlxColor>
		return getNearest(this, colors.iterator());
	
	overload public inline extern function nearest(colors:Iterator<FlxColor>):Null<FlxColor>
		return getNearest(this, colors);
	
	static function getNearest(target:FlxColor, colors:Iterator<FlxColor>):Null<FlxColor>
	{
		var closest:Null<FlxColor> = null;
		var closestDiff = -1;
		
		for (color in colors)
		{
			if (color == target)
			{
				closest = target;
				break;
			}
			
			final diff = color.getDistance(target);
			if (closest == null || diff < closestDiff)
			{
				closest = color;
				closestDiff = diff;
			}
		}
		
		return closest;
	}

	@:deprecated("to24Bit() is deprecated, use rgb field, instead.")
	public inline function to24Bit():FlxColor
		return this & 0xffffff;

	overload public inline extern function toHexString(alpha:Bool, usePrefix:Bool):String
		return toHexString(usePrefix ? "0x" : "", alpha);

	overload public inline extern function toHexString(prefix:String = "0x", includeAlpha = true):String
	{
		inline function hex(n) return StringTools.hex(n, 2);

		return prefix + (includeAlpha ? hex(alpha) : "") + hex(red) + hex(green) + hex(blue);
	}

	public inline function toWebString():String
		return "#" + toHexString(false, false);

	public inline function getInverted():FlxColor
	{
		var oldAlpha = alpha;
		var output:FlxColor = FlxColor.WHITE - this;
		output.alpha = oldAlpha;
		return output;
	}

	public inline function setRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
	{
		red = Red;
		green = Green;
		blue = Blue;
		alpha = Alpha;
		return this;
	}

	public inline function setRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
	{
		redFloat = Red;
		greenFloat = Green;
		blueFloat = Blue;
		alphaFloat = Alpha;
		return this;
	}

	public inline function setCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
	{
		redFloat = (1 - Cyan) * (1 - Black);

		greenFloat = (1 - Magenta) * (1 - Black);

		blueFloat = (1 - Yellow) * (1 - Black);

		alphaFloat = Alpha;

		return this;
	}

	public inline function setHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha = 1.0):FlxColor
	{
		var chroma = Brightness * Saturation;

		var match = Brightness - chroma;

		return setHueChromaMatch(Hue, chroma, match, Alpha);
	}

	public inline function setHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha = 1.0):FlxColor
	{
		var chroma = (1 - Math.abs(2 * Lightness - 1)) * Saturation;

		var match = Lightness - chroma / 2;

		return setHueChromaMatch(Hue, chroma, match, Alpha);
	}

	inline function setHueChromaMatch(Hue:Float, Chroma:Float, Match:Float, Alpha:Float):FlxColor
	{
		Hue %= 360;

		var hueD = Hue / 60;

		var mid = Chroma * (1 - Math.abs(hueD % 2 - 1)) + Match;

		Chroma += Match;

		switch (Std.int(hueD))
		{
			case 0:
				setRGBFloat(Chroma, mid, Match, Alpha);
			case 1:
				setRGBFloat(mid, Chroma, Match, Alpha);
			case 2:
				setRGBFloat(Match, Chroma, mid, Alpha);
			case 3:
				setRGBFloat(Match, mid, Chroma, Alpha);
			case 4:
				setRGBFloat(mid, Match, Chroma, Alpha);
			case 5:
				setRGBFloat(Chroma, Match, mid, Alpha);
		}

		return this;
	}

	public function new(Value:Int = 0)
		this = Value;

	inline function getThis():Int
		#if neko
		return Std.int(this);
		#else
		return this;
		#end

	inline function validate():Void
    {
		#if neko
		this = Std.int(this);
		#end
    }

	inline function get_red():Int
		return (getThis() >> 16) & 0xff;

	inline function get_green():Int
		return (getThis() >> 8) & 0xff;

	inline function get_blue():Int
		return getThis() & 0xff;

	inline function get_alpha():Int
		return (getThis() >> 24) & 0xff;

	inline function get_redFloat():Float
		return red / 255;

	inline function get_greenFloat():Float
		return green / 255;

	inline function get_blueFloat():Float
		return blue / 255;

	inline function get_alphaFloat():Float
		return alpha / 255;

	inline function set_red(Value:Int):Int
	{
		validate();

		this &= 0xff00ffff;

		this |= boundChannel(Value) << 16;

		return Value;
	}

	inline function set_green(Value:Int):Int
	{
		validate();

		this &= 0xffff00ff;

		this |= boundChannel(Value) << 8;

		return Value;
	}

	inline function set_blue(Value:Int):Int
	{
		validate();

		this &= 0xffffff00;

		this |= boundChannel(Value);

		return Value;
	}

	inline function set_alpha(Value:Int):Int
	{
		validate();
        
		this &= 0x00ffffff;

		this |= boundChannel(Value) << 24;

		return Value;
	}

	inline function set_redFloat(Value:Float):Float
	{
		red = Math.round(Value * 255);

		return Value;
	}

	inline function set_greenFloat(Value:Float):Float
	{
		green = Math.round(Value * 255);

		return Value;
	}

	inline function set_blueFloat(Value:Float):Float
	{
		blue = Math.round(Value * 255);

		return Value;
	}

	inline function set_alphaFloat(Value:Float):Float
	{
		alpha = Math.round(Value * 255);

		return Value;
	}

	inline function get_cyan():Float
		return (1 - redFloat - black) / brightness;

	inline function get_magenta():Float
		return (1 - greenFloat - black) / brightness;

	inline function get_yellow():Float
		return (1 - blueFloat - black) / brightness;

	inline function get_black():Float
		return 1 - brightness;

	inline function set_cyan(Value:Float):Float
	{
		setCMYK(Value, magenta, yellow, black, alphaFloat);

		return Value;
	}

	inline function set_magenta(Value:Float):Float
	{
		setCMYK(cyan, Value, yellow, black, alphaFloat);

		return Value;
	}

	inline function set_yellow(Value:Float):Float
	{
		setCMYK(cyan, magenta, Value, black, alphaFloat);

		return Value;
	}

	inline function set_black(Value:Float):Float
	{
		setCMYK(cyan, magenta, yellow, Value, alphaFloat);

		return Value;
	}

	function get_hue():Float
	{
		var hueRad = Math.atan2(Math.sqrt(3) * (greenFloat - blueFloat), 2 * redFloat - greenFloat - blueFloat);
		var hue:Float = 0;

		if (hueRad != 0)
			hue = 180 / Math.PI * hueRad;

		return hue < 0 ? hue + 360 : hue;
	}

	inline function get_brightness():Float
		return maxColor();

	inline function get_luminance():Float
		return (redFloat * 299 + greenFloat * 587 + blueFloat * 114) / 1000;

	inline function get_saturation():Float
		return (maxColor() - minColor()) / brightness;

	inline function get_lightness():Float
		return (maxColor() + minColor()) / 2;

	inline function set_hue(Value:Float):Float
	{
		setHSB(Value, saturation, brightness, alphaFloat);

		return Value;
	}

	inline function set_saturation(Value:Float):Float
	{
		setHSB(hue, Value, brightness, alphaFloat);

		return Value;
	}

	inline function set_brightness(Value:Float):Float
	{
		setHSB(hue, saturation, Value, alphaFloat);

		return Value;
	}

	inline function set_lightness(Value:Float):Float
	{
		setHSL(hue, saturation, Value, alphaFloat);

		return Value;
	}

	inline function set_rgb(value:FlxColor):FlxColor
	{
		validate();

		this = (this & 0xff000000) | (value & 0x00ffffff);

		return value;
	}

	inline function get_rgb():FlxColor
		return this & 0x00ffffff;

	inline function maxColor():Float
		return Math.max(redFloat, Math.max(greenFloat, blueFloat));

	inline function minColor():Float
		return Math.min(redFloat, Math.min(greenFloat, blueFloat));

	inline function boundChannel(Value:Int):Int
		return Value > 0xff ? 0xff : Value < 0 ? 0 : Value;
}