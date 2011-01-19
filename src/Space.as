package
{
	import caurina.transitions.Tweener;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	
	import includes.Album;
	import includes.AlbumImage;
	
	import mx.events.ResizeEvent;
	
	import sandy.core.Scene3D;
	import sandy.core.scenegraph.Camera3D;
	import sandy.core.scenegraph.Group;
	import sandy.core.scenegraph.Shape3D;
	import sandy.core.scenegraph.TransformGroup;
	import sandy.events.QueueEvent;
	import sandy.events.SandyEvent;
	import sandy.events.Shape3DEvent;
	import sandy.materials.Appearance;
	import sandy.materials.ColorMaterial;
	import sandy.primitive.Plane3D;
	import sandy.util.LoaderQueue;

	public class Space extends Sprite
	{
		static public const thumb_size:Number = 240;

		public var scene:Scene3D;
		public var tg:TransformGroup;
		public var camera:Camera3D;
		private var album:Album;
		private var start_cam_x:Number = 0;
		public var start_cam_y:Number = -50;
		private var start_cam_z:Number = -1200;
		private var w:Number
		private var h:Number;
		private var thumbs_queue:LoaderQueue;
		private var hires_queue:LoaderQueue;
		public var look_x:Number = 0;
		public var max_x:Number;
		private var dragging:Boolean = false;
		private var drag_old_x:Number = 0;
		
		public function Space(album:Album, w:Number, h:Number){
			this.album = album;
			this.album.space = this;
			this.w = w;
			this.h = h;
  		}
  		
  		public function startLoading():void {
            thumbs_queue = new LoaderQueue();
            for each (var image:XML in album.album_data.images.image) {
                thumbs_queue.add(image.@id, new URLRequest(image.@thumb_src));
            }
            thumbs_queue.addEventListener(SandyEvent.QUEUE_COMPLETE, thumbsLoaded);
            thumbs_queue.start();
        }

		public function loadImageHiRes(image:AlbumImage):void {
			hires_queue = new LoaderQueue();
			hires_queue.add(image.id, new URLRequest(image.src));
   			hires_queue.addEventListener(SandyEvent.QUEUE_COMPLETE, attachHiresBitmap);
   			hires_queue.start();
		}

		public function attachHiresBitmap(event:QueueEvent):void {
			if (album.current_image.id && album.current_image.id in hires_queue.data) {
				try {
                    album.current_image.setBitmap(hires_queue.data[album.current_image.id]);			
				}
				catch (ignored:Error) {}
			}
		}

        public function thumbsLoaded(event:QueueEvent):void {
  			this.album.app.addEventListener(ResizeEvent.RESIZE, resizeHandler);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}

		public function createScene():void {
			camera = new Camera3D(w, h);
			camera.z = start_cam_z;
			if (!scene) {
                scene = new Scene3D("scene", this, camera, new Group("root"));
			}
			else {
				scene.root.removeChildByName("wall");
			}
			tg = new TransformGroup('wall');
			album.createPlaceholders(tg);
			var p:Plane3D = new Plane3D("p", 3000, max_x * 1.25);
			p.x = max_x / 2;
			p.y = 0;
			p.z = 10;
			p.appearance = new Appearance(
				new ColorMaterial(0x000000)
			);
			p.enableEvents = true;
			p.addEventListener(MouseEvent.CLICK, bgClicked);
			tg.enableEvents = true;
			tg.addEventListener(MouseEvent.MOUSE_MOVE, doDragging);
			tg.addEventListener(MouseEvent.MOUSE_UP, stopDragging);
			tg.addEventListener(MouseEvent.MOUSE_DOWN, startDragging);
			tg.addChild(p);
			scene.root.addChild(tg);

			camera.x = start_cam_x;
			camera.y = start_cam_y;
			tg.rotateY = 0;
		}				
		
		public function bgClicked(event:Shape3DEvent):void {
			resetCurrentImage();
		}

		public function startDragging(event:Shape3DEvent):void {
			const image:AlbumImage = album.getImageFromShape(event.target as Shape3D);
			if (!image || image != album.current_image) {
				dragging = true;
				drag_old_x = event.point.x;
			}
//			trace("startDrag: " + event.point);
		}

		public function doDragging(event:Shape3DEvent):void {
			if (dragging) {
				if((event.event as MouseEvent).buttonDown) {
					resetCurrentImage();
					var delta:Number = drag_old_x - event.point.x;
					var new_x:Number = event.point.x + delta * 10;
					//Tweener.addTween(this, {look_x: new_x, time:1.5});
					Tweener.addTween(camera, {x: new_x, time:1.5});
					Tweener.addTween(album.app.scroller, {value: new_x, delay:0.1, time:1});
				}
				stopDragging(event);
			}
		}

		public function stopDragging(event:Shape3DEvent):void {
			dragging = false;
//			trace("stopDrag: " + event.point);
		}

		public function selectImage(image:AlbumImage, current:AlbumImage):void {
			var ix:Number = image.x;// + image.width / 2;
			var iy:Number = image.y + image.height / 2;
			var cx:Number = album.app.scroller.value;
			var x_delta:Number = ix - cx;
			Tweener.addTween(image, {z: -100, time:1, delay: 0, transition: "linear"});
			Tweener.addTween(camera, {y:image.y, time:1.5, transition: "linear"});
			scrollTo(ix, iy, x_delta, 1.5);
			album.app.scroller.value = ix;
		}
		
		public function scrollTo(x:Number, y:Number, x_delta:Number, extra_delay:Number=0):void {
			var tilt:Number = 1.5 * max_x * Math.min(camera.z * -1, Math.sin(Math.abs(x_delta) / max_x)) * (x_delta > 1 ? 1 : -1); 
			var cam_reset_delay:Number = extra_delay ? Math.abs(tilt * 2 / max_x) : 0;
			var do_delay:Boolean = Math.abs(x_delta) > thumb_size * 3;
			//Tweener.addTween(camera, {x:x - tilt, time:0.5, transition: "linear"});
			Tweener.addTween(this, {look_x:x, time:0.5, transition: "linear"});
			var delay:Number = do_delay ? Math.max(0.5 + extra_delay, cam_reset_delay) : 0;
			var time:Number = Math.max(0.5 + extra_delay, cam_reset_delay);
			Tweener.addTween(camera, {x:x, delay: 0, time: time, transition: "linear", onComplete: zoomCurrentImage});
			zoomCurrentImage();
		}

		public function zoomCurrentImage(): void {
			if (album.current_image) {
				loadImageHiRes(album.current_image);
				Tweener.addTween(album.app.spriteContainer, {x: 150, time:1, transition: "linear"});
				Tweener.addTween(album.current_image, {z: -1000, time:1, transition: "linear"});
				Tweener.addTween(camera, {fov:25, time:1, transition: "linear"});
                album.app.populateInfo(album.current_image);
			}
		}

		public function unSelectImage(image:AlbumImage):void {
			if (image) {
				image.setThumbBitmap();
				Tweener.addTween(album.app.spriteContainer, {x: 0, time:0.7, transition: "linear"});
				Tweener.addTween(image, {x:image.start_x, y:image.start_y, z:image.start_z, time:0.7, y:image.y, transition:"linear"});
				Tweener.addTween(camera, {fov:45, time:1.0,  transition: "linear"});
				image.unHighLight();
                album.app.populateInfo(null);
			}
		}

		public function resizeHandler(event:ResizeEvent):void {
			camera.viewport.width = event.target.width;
			camera.viewport.height = event.target.height;
		}
			
		public function resetCurrentImage():void {
			unSelectImage(album.current_image);
			album.current_image = null;
		}

		public function enterFrameHandler(event:Event):void {
			var look_y:Number = camera.y;
			var look_z:Number = 0;
			if (album.current_image) {
				look_y = album.current_image.y + album.current_image.height / 2;
				look_z = album.current_image.z;
			}
			camera.lookAt(look_x, camera.y, look_z);
			scene.render();
		}
	}
}