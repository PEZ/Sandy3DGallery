package includes
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import sandy.core.scenegraph.Shape3D;
	import sandy.materials.Appearance;
	import sandy.materials.BitmapMaterial;
	import sandy.primitive.Plane3D;

	public class AlbumMirroredImage extends AlbumImage {
		public var mirror_shape:Shape3D;

		public function AlbumMirroredImage(image_info:XML, album:Album, bitmap:Bitmap) {
			super(image_info, album, bitmap);
		}
		
		override public function set x(v:Number):void {
			super.x = v;
			mirror_shape.x = v;
		}
		
		override public function set y(v:Number):void {
			super.y = v;
			mirror_shape.y = v - height - 15;
		}
		
		override public function set z(v:Number):void {
			super.z = v;
			mirror_shape.z = v;
		}

		override public function setBitmap(bitmap:Bitmap):void {
			super.setBitmap(bitmap);
			createMirror(bitmap.bitmapData);
		}

		override public function select():void {
			super.select();
			mirror_shape.container.filters = [
				new GlowFilter(0x777777, .7, 15, 15)
			];
		}

		override public function highLight():void {
			super.highLight();
			if (this != album.current_image) {
				mirror_shape.container.filters = [
					new GlowFilter(0x777777, .7, 4, 4)
				];
			}
		}

		override public function unHighLight():void {
			super.unHighLight();
			mirror_shape.container.filters = [];
		}

		private function createMirror(bitmap_data:BitmapData):void {
			const fall_off:Number = 0.65;
			const w:Number = bitmap_data.width;
			const h:Number = bitmap_data.height;
            var gradientBitmap:BitmapData = new BitmapData(w, h, true, 0x00000000);
            var gradientMatrix:Matrix = new Matrix();
            var gradientSprite:Sprite = new Sprite();
            gradientMatrix.createGradientBox(w, h, Math.PI/2, 0, h * (1.0 - fall_off));
            gradientSprite.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], [0, 0.76], [0, 255], gradientMatrix);
            gradientSprite.graphics.drawRect(0, h * (1.0 - fall_off), w, h * fall_off);
            gradientSprite.graphics.endFill();
            gradientBitmap.draw(gradientSprite, new Matrix());

            var rect:Rectangle = new Rectangle(0, 0, w, h);
            var mirror_bitmap:BitmapData = new BitmapData(w, h, true, 0x00000000);
            mirror_bitmap.copyPixels(bitmap_data, rect, new Point(), gradientBitmap);
			var flipMatrix:Matrix = new Matrix();
			flipMatrix.scale(1, -1);
			flipMatrix.translate(0, h);
            var mirror_bitmap2:BitmapData = new BitmapData(w, h, true, 0x00000000);
            mirror_bitmap2.draw(mirror_bitmap, flipMatrix);	
            mirror_bitmap.copyPixels(bitmap_data, rect, new Point(), gradientBitmap);
            
            const mattr:BitmapMaterial = new BitmapMaterial(mirror_bitmap2, null, _precision);
            mattr.repeat = false;
            if (!mirror_shape) {
				mirror_shape = new Plane3D(id, h, w);
            }
			mirror_shape.appearance = new Appearance(mattr);
			//mirror_shape.container.alpha = 0.5;
			//mirror_shape.container.filters = [new BlurFilter(5, 10)];
			mirror_shape.enableEvents = true;
			mirror_shape.addEventListener(MouseEvent.CLICK, album.space.bgClicked);
		}
	}
}