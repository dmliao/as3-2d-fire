package test
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import test.PNGEnc;
	
	public class Screenshot extends Sprite
	{
		
		public function Screenshot()
		{
		//	stage.addEventListener(MouseEvent.CLICK,takeScreenshot);
		}
	
		public function takeScreenshot():void
		{
			
			var bmd:BitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, true, 0);
			var bm:Bitmap = new Bitmap(bmd, "auto",true);
			
			bmd.draw(stage); // i wrote my example code in my document class, so "this" refers to my document class and the whole stage is drawn into the bitmapdata
			
			var bild:ByteArray = PNGEnc.encode(bmd);
			
			var file:FileReference = new FileReference();
			
			file.save(bild, "screenshot.png");
		}
	}
}