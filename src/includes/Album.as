package includes
{
	import flash.display.Bitmap;
	import flash.utils.Dictionary;
	
	import sandy.core.scenegraph.Shape3D;
	import sandy.core.scenegraph.TransformGroup;
	
	public class Album {
		[Embed(source="../icons/ajax-loader.gif")]
		private var Picture:Class;
		private var spinner:Bitmap = new Picture();
		[Bindable]
		public var current_image:AlbumImage;
		public var space:Space;
		public var app:ThreeDeeGallery;
		
		public function Album(app:ThreeDeeGallery):void {
			super();
			this.app = app;
		}

		private var _images:Dictionary = new Dictionary();
		private var _shapes_to_image:Dictionary = new Dictionary();
		private var _album_data:XML;

		public function addImage(image:AlbumImage):void {
			_images[image.id] = image;
			_shapes_to_image[image.shape] = image;
		}

		public function createPlaceholders(tg:TransformGroup):void {
			const rows:int = 2;
			var i:int = 0;
			var x:Number = 0;

			var columnWidth:Number = 0;
			for each (var image_info:XML in _album_data.images.image) {
				var image:AlbumImage;
				if (i % rows == rows - 1) {
					image = new AlbumMirroredImage(image_info, this, spinner);
					tg.addChild((image as AlbumMirroredImage).mirror_shape);					
				}
				else {
				 	image = new AlbumImage(image_info, this, spinner);
				}
				tg.addChild(image.shape);					
				columnWidth = Math.max(columnWidth, image.width);
				if (i % rows == 0) {
					x += columnWidth + 15;
				};
				var y:Number = image.height * 1.3 - i % rows * (image.height * 1.3);
				image.x = image.start_x = x;
				image.y = image.start_y = y;
				image.z = image.start_z = 0;
				this.addImage(image);
				i++;
			}
			space.max_x = x;
			app.scroller.maximum = x;
			//selectImageById(item.@id);
			app.scroller.value = x / 10;
			app.scrollImagesTo(x / 10);

		}
		
		public function getImage(id:String):AlbumImage {
			return _images[id];
		}

		public function getImageFromShape(shape:Shape3D):AlbumImage {
			if (shape in _shapes_to_image) {
				return _shapes_to_image[shape];
			}
			else {
				return null;
			}
		}

		public function set album_data(data:XML):void {
			_album_data = data;
		}
		
		public function get album_data():XML {
			return _album_data;
		}
		
		public function selectImageById(id:String):void {
			selectImage(_images[id]);
		}

		public function selectImage(image:AlbumImage):void {
			if (!current_image || current_image != image) {
				space.selectImage(image, current_image);
				image.select();
			}
			if (current_image != image) {
				space.unSelectImage(current_image);
			}			
			current_image = image;
		}

		public function highLightImageById(id:String):void {
			_images[id].highLight();
		}

		public function unHighLightImageById(id:String):void {
			_images[id].unHighLight();
		}
	}
}