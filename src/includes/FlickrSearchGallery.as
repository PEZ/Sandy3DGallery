package includes {	
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class FlickrSearchGallery {
		public var service:HTTPService = new HTTPService();
		private var _gallery:XML;
		private var _callback:Function;

		public function FlickrSearchGallery() {
			service.url = 'http://api.flickr.com/services/rest/';
			service.request.method='flickr.photos.search';
			service.request.api_key='eae1a90b9a7b5b00c998a35c2a6335c5';
			service.request.per_page='180';
			service.request.extras='o_dims,url_t,url_m,url_o';
            service.resultFormat = 'xml';
		}

		public function search(q:String, callback:Function):void {
			_callback = callback;
			_gallery = <album id='FlickrSearch'><images></images></album>;
			service.cancel();
			service.request.text = q;
            service.addEventListener(ResultEvent.RESULT, onServerResponse);
			service.send();
		}

		private function onServerResponse(event:ResultEvent):void {
          service.removeEventListener(ResultEvent.RESULT, onServerResponse);
		  //try {
		    var r:XML = XML(event.result);
		    for each (var photo:XML in r.photos.photo) {
		    	var image_xml:XML = new XML(<image/>);
		    	image_xml.@id = photo.@id;
		    	image_xml.@name = photo.@title;
                image_xml.@thumb_src = photo.@url_t;
                if (photo.@originalsecret) {
                    image_xml.@src = photo.@url_o;
                }
		    	image_xml.@width = photo.@width_t;
		    	image_xml.@height = photo.@height_t;
		    	_gallery.images.appendChild(image_xml);
		    }
		    _callback(_gallery);
		  //} catch(ignored:Error) {
		  //}
		}
	}
}