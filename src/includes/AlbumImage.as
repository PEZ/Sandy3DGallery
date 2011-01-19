package includes {
	import flash.display.Bitmap;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	
	import sandy.core.scenegraph.Shape3D;
	import sandy.materials.Appearance;
	import sandy.materials.BitmapMaterial;
	import sandy.materials.ColorMaterial;
	import sandy.primitive.Plane3D;

	public class AlbumImage extends EventDispatcher {
		public var shape:Shape3D;
		public var id:String;
		public var name:String;
		public var src:String;
		public var width:Number;
		public var height:Number;
		public var start_x:Number;
		public var start_y:Number;
		public var start_z:Number = 0;

		protected var _bitmap:Bitmap;
		protected var _precision:uint = 9;
		[Bindable]
		public var image_info:XML;
		public var album:Album;
		public var rating:Number;

		protected var _x:Number;
		protected var _y:Number;
		protected var _z:Number;

		public function AlbumImage(image_info:XML, album:Album, bitmap:Bitmap) {
			this.image_info = image_info;
			this.id = image_info.@id;
			this.name = image_info.@name;
			this.src = image_info.@src;
			this.rating = image_info.@rating;
			this.album = album;
			this._bitmap = bitmap;
			this.width = image_info.@width;
			this.height = image_info.@height;
			createPlane();
		}
		
		public function get x():Number {
			return this._x;
		}
		
		public function set x(v:Number):void {
			this._x = v;
			shape.x = v;
		}
		
		public function get y():Number {
			return this._y;
		}
		
		public function set y(v:Number):void {
			this._y = v;
			shape.y = v;
		}
		
		public function get z():Number {
			return this._z;
		}
		
		public function set z(v:Number):void {
			this._z = v;
			shape.z = v;
		}
		
		public function addComment(comment:XML):void {
			image_info.comments.appendChild(comment);
		}

		private function createPlane():void {
			shape = new Plane3D(this.name, this.height, this.width, 1, 1, null, 'quad');
			shape.enableBackFaceCulling = false;
			shape.useSingleContainer = true;
			shape.enableEvents = true;
            shape.appearance = new Appearance(
                new ColorMaterial(0x000000)
            );
   			setThumbBitmap();
			shape.container.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			shape.container.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
			shape.container.addEventListener(MouseEvent.CLICK, clickHandler);
			shape.container.useHandCursor = true;
			shape.container.buttonMode = true;
		}

		public function setBitmap(bitmap:Bitmap):void {
            const mattr:BitmapMaterial = new BitmapMaterial(bitmap.bitmapData, null, _precision);
            mattr.repeat = false;
			shape.appearance = new Appearance(mattr);
		}

		public function setThumbBitmap():void {
			setBitmap(_bitmap);
		}

		private function clickHandler(event:MouseEvent):void {
			if (this != album.current_image) {
				album.selectImage(this);
			}
		}	

		private function mouseOverHandler(event:MouseEvent):void {
			highLight();
		}

		private function mouseOutHandler(event:MouseEvent):void {
			if (this != album.current_image) {
				unHighLight();
			}
		}

		public function select():void {
			shape.container.filters = [
				new GlowFilter(0xffffff, 1, 15, 15)
			];
		}

		public function highLight():void {
			if (this != album.current_image) {
				shape.container.filters = [
					new GlowFilter(0xffffff, 1, 5, 5)
				];
			}
		}

		public function unHighLight():void {
			shape.container.filters = [];
		}
	}
}