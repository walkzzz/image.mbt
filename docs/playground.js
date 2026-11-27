function _M0TPB5ArrayGcE(param0, param1) {
  this.buf = param0;
  this.len = param1;
}
function $oob() {
  throw new Error("Index out of bounds");
}
class $PanicError extends Error {}
function $panic(message) {
  throw new $PanicError(message);
}
function _M0TPB13StringBuilder(param0) {
  this.val = param0;
}
function _M0TPC16string10StringView(param0, param1, param2) {
  this.str = param0;
  this.start = param1;
  this.end = param2;
}
var _M0FPB19int__to__string__js = (x, radix) => {
  return x.toString(radix);
};
function _M0TPB5ArrayGyE(param0, param1) {
  this.buf = param0;
  this.len = param1;
}
function _M0TPB5ArrayGiE(param0, param1) {
  this.buf = param0;
  this.len = param1;
}
function _M0TPB5ArrayGbE(param0, param1) {
  this.buf = param0;
  this.len = param1;
}
var $bytes_literal$0 = new Uint8Array();
var _M0FPC28encoding4utf816encode__utf8__js = (() => {
   const encoder = new TextEncoder();
   return function(src, start, len, bom) {
     const end = start + len;
     const encoded = encoder.encode(src.slice(start, end));
     if (!bom) {
       return encoded;
     }
     const result = new Uint8Array(encoded.length + 3);
     result[0] = 0xEF;
     result[1] = 0xBB;
     result[2] = 0xBF;
     result.set(encoded, 3);
     return result;
   };
 })();
var _M0FPC28encoding4utf816decode__utf8__js = ((preserveBOMDecoder, dropBOMDecoder) => function(bytes, start, len, preserveBOM) {
   try {
     const end = start + len;
     const slice = bytes.subarray(start, end);
     const decoder = preserveBOM ? preserveBOMDecoder : dropBOMDecoder;
     return [decoder.decode(slice)];
   } catch (_) {
     return [];
   }
 })(
   new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }),
   new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }),
 );
function _M0TPC15bytes9BytesView(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
function _M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE2Ok.prototype.$tag = 1;
function _M0DTPC15error5Error51walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eFileIO(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error51walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eFileIO.prototype.$tag = 4;
function _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat.prototype.$tag = 3;
function _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed.prototype.$tag = 2;
function _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eEncodeFailed(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eEncodeFailed.prototype.$tag = 1;
function _M0DTPC15error5Error60moonbitlang_2fcore_2fencoding_2futf8_2eMalformed_2eMalformed(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error60moonbitlang_2fcore_2fencoding_2futf8_2eMalformed_2eMalformed.prototype.$tag = 0;
function _M0TPC13ref3RefGiE(param0) {
  this.val = param0;
}
function _M0TPB5ArrayGsE(param0, param1) {
  this.buf = param0;
  this.len = param1;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16WebpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16WebpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16WebpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16WebpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec16WebpInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8) {
  this.width = param0;
  this.height = param1;
  this.format = param2;
  this.has_alpha = param3;
  this.has_animation = param4;
  this.has_icc_profile = param5;
  this.has_exif = param6;
  this.has_xmp = param7;
  this.num_channels = param8;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16ApngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16ApngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16ApngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16ApngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec16ApngInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9) {
  this.width = param0;
  this.height = param1;
  this.bit_depth = param2;
  this.color_type = param3;
  this.color_type_name = param4;
  this.num_channels = param5;
  this.has_alpha = param6;
  this.num_frames = param7;
  this.num_plays = param8;
  this.is_animated = param9;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16AvifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16AvifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16AvifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16AvifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TPB8MutLocalGiE(param0) {
  this.val = param0;
}
function _M0TPB8MutLocalGbE(param0) {
  this.val = param0;
}
function _M0TPB8MutLocalGsE(param0) {
  this.val = param0;
}
function _M0TP37walkzzz13image_2ecodec5codec16AvifInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15) {
  this.width = param0;
  this.height = param1;
  this.bit_depth = param2;
  this.num_channels = param3;
  this.has_alpha = param4;
  this.rotation = param5;
  this.mirror = param6;
  this.color_type = param7;
  this.color_primaries = param8;
  this.transfer_characteristics = param9;
  this.matrix_coefficients = param10;
  this.full_range = param11;
  this.av1_profile = param12;
  this.av1_level = param13;
  this.av1_tier = param14;
  this.av1_monochrome = param15;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15BmpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15BmpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15BmpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15BmpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15BmpInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10) {
  this.width = param0;
  this.height = param1;
  this.bit_depth = param2;
  this.num_channels = param3;
  this.has_alpha = param4;
  this.compression = param5;
  this.compression_name = param6;
  this.is_bottom_up = param7;
  this.dib_size = param8;
  this.num_colors = param9;
  this.data_offset = param10;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15CurInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9) {
  this.icon_type = param0;
  this.num_images = param1;
  this.widths = param2;
  this.heights = param3;
  this.hotspot_xs = param4;
  this.hotspot_ys = param5;
  this.width = param6;
  this.height = param7;
  this.num_channels = param8;
  this.has_alpha = param9;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15GifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15GifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15GifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15GifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15GifInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10) {
  this.width = param0;
  this.height = param1;
  this.version = param2;
  this.has_global_color_table = param3;
  this.global_color_table_size = param4;
  this.color_resolution = param5;
  this.is_sorted = param6;
  this.background_color_index = param7;
  this.pixel_aspect_ratio = param8;
  this.num_channels = param9;
  this.has_alpha = param10;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15HdrInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15HdrInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15HdrInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15HdrInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TPB9ArrayViewGyE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
function _M0TP37walkzzz13image_2ecodec5codec15HdrInfoExtended(param0, param1, param2, param3, param4) {
  this.width = param0;
  this.height = param1;
  this.num_channels = param2;
  this.has_alpha = param3;
  this.format = param4;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16HeifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16HeifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16HeifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16HeifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec16HeifInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15, param16, param17) {
  this.width = param0;
  this.height = param1;
  this.bit_depth = param2;
  this.num_channels = param3;
  this.has_alpha = param4;
  this.rotation = param5;
  this.mirror = param6;
  this.color_type = param7;
  this.color_primaries = param8;
  this.transfer_characteristics = param9;
  this.matrix_coefficients = param10;
  this.full_range = param11;
  this.hevc_profile = param12;
  this.hevc_level = param13;
  this.hevc_tier = param14;
  this.hevc_chroma_format = param15;
  this.hevc_bit_depth_luma = param16;
  this.hevc_bit_depth_chroma = param17;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16IcnsInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16IcnsInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16IcnsInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16IcnsInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec16IcnsInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8) {
  this.file_size = param0;
  this.num_icons = param1;
  this.icon_types = param2;
  this.icon_sizes = param3;
  this.is_png_list = param4;
  this.width = param5;
  this.height = param6;
  this.num_channels = param7;
  this.has_alpha = param8;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15IcoInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9) {
  this.icon_type = param0;
  this.icon_type_name = param1;
  this.num_images = param2;
  this.widths = param3;
  this.heights = param4;
  this.bit_depths = param5;
  this.width = param6;
  this.height = param7;
  this.num_channels = param8;
  this.has_alpha = param9;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16JpegInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16JpegInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16JpegInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16JpegInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec16JpegInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9) {
  this.width = param0;
  this.height = param1;
  this.precision = param2;
  this.num_components = param3;
  this.is_grayscale = param4;
  this.is_progressive = param5;
  this.sof_marker = param6;
  this.sof_name = param7;
  this.num_channels = param8;
  this.has_alpha = param9;
}
function _M0TP37walkzzz13image_2ecodec5codec12JxlBitReader(param0, param1, param2) {
  this.data = param0;
  this.byte_pos = param1;
  this.bit_pos = param2;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec18JpegXlInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec18JpegXlInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec18JpegXlInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec18JpegXlInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec18JpegXlInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7) {
  this.width = param0;
  this.height = param1;
  this.bit_depth = param2;
  this.num_channels = param3;
  this.has_alpha = param4;
  this.is_lossless = param5;
  this.is_codestream = param6;
  this.orientation = param7;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15PngInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10) {
  this.width = param0;
  this.height = param1;
  this.bit_depth = param2;
  this.color_type = param3;
  this.color_type_name = param4;
  this.num_channels = param5;
  this.has_alpha = param6;
  this.is_palette = param7;
  this.compression_method = param8;
  this.filter_method = param9;
  this.interlace_method = param10;
}
function _M0DTPC16result6ResultGiRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGiRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PnmInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PnmInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PnmInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PnmInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15PnmInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7) {
  this.width = param0;
  this.height = param1;
  this.format_type = param2;
  this.maxval = param3;
  this.bit_depth = param4;
  this.num_channels = param5;
  this.has_alpha = param6;
  this.is_binary = param7;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PsdInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PsdInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PsdInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PsdInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15PsdInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10) {
  this.width = param0;
  this.height = param1;
  this.bit_depth = param2;
  this.channel_count = param3;
  this.num_channels = param4;
  this.has_alpha = param5;
  this.color_mode = param6;
  this.color_mode_name = param7;
  this.compression = param8;
  this.compression_name = param9;
  this.version = param10;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15QoiInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15QoiInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15QoiInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15QoiInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15QoiInfoExtended(param0, param1, param2, param3, param4, param5, param6) {
  this.width = param0;
  this.height = param1;
  this.channels = param2;
  this.colorspace = param3;
  this.colorspace_name = param4;
  this.num_channels = param5;
  this.has_alpha = param6;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec15TgaInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11) {
  this.width = param0;
  this.height = param1;
  this.image_type = param2;
  this.image_type_name = param3;
  this.bit_depth = param4;
  this.num_channels = param5;
  this.has_alpha = param6;
  this.is_bottom_up = param7;
  this.id_length = param8;
  this.color_map_type = param9;
  this.x_origin = param10;
  this.y_origin = param11;
}
function _M0DTPC16result6ResultGRPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryERP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryERP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryERP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryERP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(param0, param1) {
  this.buf = param0;
  this.len = param1;
}
function _M0TP37walkzzz13image_2ecodec5codec12TiffIfdEntry(param0, param1, param2, param3) {
  this.tag = param0;
  this.type_id = param1;
  this.count = param2;
  this.value_or_offset = param3;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec5codec11TiffContext(param0, param1) {
  this.data = param0;
  this.little_endian = param1;
}
function _M0TP37walkzzz13image_2ecodec5codec16TiffInfoExtended(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12) {
  this.width = param0;
  this.height = param1;
  this.bit_depth = param2;
  this.samples_per_pixel = param3;
  this.num_channels = param4;
  this.has_alpha = param5;
  this.compression = param6;
  this.compression_name = param7;
  this.photometric = param8;
  this.photometric_name = param9;
  this.orientation = param10;
  this.resolution_unit = param11;
  this.is_little_endian = param12;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Avif(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Avif.prototype.$tag = 0;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Heif(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Heif.prototype.$tag = 1;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended6JpegXl(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended6JpegXl.prototype.$tag = 2;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Webp(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Webp.prototype.$tag = 3;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Tiff(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Tiff.prototype.$tag = 4;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Psd(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Psd.prototype.$tag = 5;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Bmp(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Bmp.prototype.$tag = 6;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Gif(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Gif.prototype.$tag = 7;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Png(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Png.prototype.$tag = 8;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Jpeg(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Jpeg.prototype.$tag = 9;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Qoi(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Qoi.prototype.$tag = 10;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Tga(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Tga.prototype.$tag = 11;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Hdr(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Hdr.prototype.$tag = 12;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Pnm(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Pnm.prototype.$tag = 13;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Ico(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Ico.prototype.$tag = 14;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Cur(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Cur.prototype.$tag = 15;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Icns(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Icns.prototype.$tag = 16;
function _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Apng(param0) {
  this._0 = param0;
}
_M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Apng.prototype.$tag = 17;
function _M0TP37walkzzz13image_2ecodec5codec9BitWriter(param0, param1, param2) {
  this.out = param0;
  this.buf = param1;
  this.cnt = param2;
}
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(param0, param1, param2, param3, param4, param5, param6) {
  this.format = param0;
  this.format_name = param1;
  this.width = param2;
  this.height = param3;
  this.channels = param4;
  this.bit_depth = param5;
  this.has_alpha = param6;
}
function _M0DTPC16result6ResultGsRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGsRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
function _M0TP37walkzzz12image_2ecore5types5Image(param0, param1, param2, param3) {
  this.width = param0;
  this.height = param1;
  this.channels = param2;
  this.data = param3;
}
function _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE2Ok.prototype.$tag = 1;
var _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger = { method_0: _M0IPB13StringBuilderPB6Logger13write__string, method_1: _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE, method_2: _M0IPB13StringBuilderPB6Logger11write__view, method_3: _M0IPB13StringBuilderPB6Logger11write__char, method_4: _M0IP016_24default__implPB6Logger28write__string__interpolationGRPB13StringBuilderE, method_5: _M0IP016_24default__implPB6Logger5writeGRPB13StringBuilderE };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS754 = { _0: 128, _1: true };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS755 = { _0: 256, _1: true };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS756 = { _0: 512, _1: true };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS757 = { _0: 1024, _1: true };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS758 = { _0: 16, _1: true };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS759 = { _0: 32, _1: true };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS760 = { _0: 64, _1: true };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS761 = { _0: 256, _1: true };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS762 = { _0: 16, _1: false };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS763 = { _0: 32, _1: false };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS764 = { _0: 16, _1: false };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS765 = { _0: 32, _1: false };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS766 = { _0: 64, _1: false };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS767 = { _0: 128, _1: false };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS768 = { _0: 256, _1: false };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS769 = { _0: 512, _1: false };
var _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS770 = { _0: 0, _1: false };
var _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1337 = { _0: 19, _1: 7 };
var _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1338 = { _0: 34, _1: 10 };
var _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1339 = { _0: 55, _1: 15 };
var _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1340 = { _0: 80, _1: 20 };
var _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1341 = { _0: 108, _1: 26 };
var _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1342 = { _0: 19, _1: 7 };
var _M0FP37walkzzz11image_2embt10playground10hex__chars = new _M0TPB5ArrayGcE([48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102], 16);
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1352 = { _0: 0, _1: 0 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1353 = { _0: 8, _1: 0 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1354 = { _0: 8, _1: 1 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1355 = { _0: 8, _1: 2 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1356 = { _0: 8, _1: 3 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1357 = { _0: 8, _1: 4 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1358 = { _0: 8, _1: 5 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1359 = { _0: 8, _1: 7 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1360 = { _0: 8, _1: 8 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1361 = { _0: 7, _1: 8 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1362 = { _0: 5, _1: 8 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1363 = { _0: 4, _1: 8 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1364 = { _0: 3, _1: 8 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1365 = { _0: 2, _1: 8 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1366 = { _0: 1, _1: 8 };
var _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1367 = { _0: 0, _1: 8 };
var _M0FP37walkzzz12image_2ecore5types11clamp__byte = _M0FP37walkzzz12image_2ecore10safe__math11clamp__byte;
var _M0FP37walkzzz12image_2ecore5types12clamp__coord = _M0FP37walkzzz12image_2ecore10safe__math12clamp__coord;
function _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGcEE(dst, dst_offset, src, src_offset, len) {
  if (dst === src && dst_offset < src_offset) {
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < len) {
        const _tmp$2 = dst_offset + i | 0;
        const _tmp$3 = src_offset + i | 0;
        if (_tmp$2 >>> 0 < dst.length) {
          dst[_tmp$2] = _tmp$3 >>> 0 < src.length ? src[_tmp$3] : $oob();
        } else {
          $oob();
        }
        _tmp = i + 1 | 0;
        continue;
      } else {
        return;
      }
    }
  } else {
    let _tmp = len - 1 | 0;
    let _tmp$2 = len > 0;
    while (true) {
      const i = _tmp;
      const _more = _tmp$2;
      if (_more) {
        const _tmp$3 = dst_offset + i | 0;
        const _tmp$4 = src_offset + i | 0;
        if (_tmp$3 >>> 0 < dst.length) {
          dst[_tmp$3] = _tmp$4 >>> 0 < src.length ? src[_tmp$4] : $oob();
        } else {
          $oob();
        }
        _tmp = i - 1 | 0;
        _tmp$2 = i > 0;
        continue;
      } else {
        return;
      }
    }
  }
}
function _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryEE(dst, dst_offset, src, src_offset, len) {
  if (dst === src && dst_offset < src_offset) {
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < len) {
        const _tmp$2 = dst_offset + i | 0;
        const _tmp$3 = src_offset + i | 0;
        if (_tmp$2 >>> 0 < dst.length) {
          dst[_tmp$2] = _tmp$3 >>> 0 < src.length ? src[_tmp$3] : $oob();
        } else {
          $oob();
        }
        _tmp = i + 1 | 0;
        continue;
      } else {
        return;
      }
    }
  } else {
    let _tmp = len - 1 | 0;
    let _tmp$2 = len > 0;
    while (true) {
      const i = _tmp;
      const _more = _tmp$2;
      if (_more) {
        const _tmp$3 = dst_offset + i | 0;
        const _tmp$4 = src_offset + i | 0;
        if (_tmp$3 >>> 0 < dst.length) {
          dst[_tmp$3] = _tmp$4 >>> 0 < src.length ? src[_tmp$4] : $oob();
        } else {
          $oob();
        }
        _tmp = i - 1 | 0;
        _tmp$2 = i > 0;
        continue;
      } else {
        return;
      }
    }
  }
}
function _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGiEE(dst, dst_offset, src, src_offset, len) {
  if (dst === src && dst_offset < src_offset) {
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < len) {
        const _tmp$2 = dst_offset + i | 0;
        const _tmp$3 = src_offset + i | 0;
        if (_tmp$2 >>> 0 < dst.length) {
          dst[_tmp$2] = _tmp$3 >>> 0 < src.length ? src[_tmp$3] : $oob();
        } else {
          $oob();
        }
        _tmp = i + 1 | 0;
        continue;
      } else {
        return;
      }
    }
  } else {
    let _tmp = len - 1 | 0;
    let _tmp$2 = len > 0;
    while (true) {
      const i = _tmp;
      const _more = _tmp$2;
      if (_more) {
        const _tmp$3 = dst_offset + i | 0;
        const _tmp$4 = src_offset + i | 0;
        if (_tmp$3 >>> 0 < dst.length) {
          dst[_tmp$3] = _tmp$4 >>> 0 < src.length ? src[_tmp$4] : $oob();
        } else {
          $oob();
        }
        _tmp = i - 1 | 0;
        _tmp$2 = i > 0;
        continue;
      } else {
        return;
      }
    }
  }
}
function _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGbEE(dst, dst_offset, src, src_offset, len) {
  if (dst === src && dst_offset < src_offset) {
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < len) {
        const _tmp$2 = dst_offset + i | 0;
        const _tmp$3 = src_offset + i | 0;
        if (_tmp$2 >>> 0 < dst.length) {
          dst[_tmp$2] = _tmp$3 >>> 0 < src.length ? src[_tmp$3] : $oob();
        } else {
          $oob();
        }
        _tmp = i + 1 | 0;
        continue;
      } else {
        return;
      }
    }
  } else {
    let _tmp = len - 1 | 0;
    let _tmp$2 = len > 0;
    while (true) {
      const i = _tmp;
      const _more = _tmp$2;
      if (_more) {
        const _tmp$3 = dst_offset + i | 0;
        const _tmp$4 = src_offset + i | 0;
        if (_tmp$3 >>> 0 < dst.length) {
          dst[_tmp$3] = _tmp$4 >>> 0 < src.length ? src[_tmp$4] : $oob();
        } else {
          $oob();
        }
        _tmp = i - 1 | 0;
        _tmp$2 = i > 0;
        continue;
      } else {
        return;
      }
    }
  }
}
function _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGyEE(dst, dst_offset, src, src_offset, len) {
  if (dst === src && dst_offset < src_offset) {
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < len) {
        const _tmp$2 = dst_offset + i | 0;
        const _tmp$3 = src_offset + i | 0;
        if (_tmp$2 >>> 0 < dst.length) {
          dst[_tmp$2] = _tmp$3 >>> 0 < src.length ? src[_tmp$3] : $oob();
        } else {
          $oob();
        }
        _tmp = i + 1 | 0;
        continue;
      } else {
        return;
      }
    }
  } else {
    let _tmp = len - 1 | 0;
    let _tmp$2 = len > 0;
    while (true) {
      const i = _tmp;
      const _more = _tmp$2;
      if (_more) {
        const _tmp$3 = dst_offset + i | 0;
        const _tmp$4 = src_offset + i | 0;
        if (_tmp$3 >>> 0 < dst.length) {
          dst[_tmp$3] = _tmp$4 >>> 0 < src.length ? src[_tmp$4] : $oob();
        } else {
          $oob();
        }
        _tmp = i - 1 | 0;
        _tmp$2 = i > 0;
        continue;
      } else {
        return;
      }
    }
  }
}
function _M0MPB18UninitializedArray12unsafe__blitGyE(dst, dst_offset, src, src_offset, len) {
  _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGyEE(dst, dst_offset, src, src_offset, len);
}
function _M0MPB18UninitializedArray12unsafe__blitGcE(dst, dst_offset, src, src_offset, len) {
  _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGcEE(dst, dst_offset, src, src_offset, len);
}
function _M0MPB18UninitializedArray12unsafe__blitGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(dst, dst_offset, src, src_offset, len) {
  _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryEE(dst, dst_offset, src, src_offset, len);
}
function _M0MPB18UninitializedArray12unsafe__blitGiE(dst, dst_offset, src, src_offset, len) {
  _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGiEE(dst, dst_offset, src, src_offset, len);
}
function _M0MPB18UninitializedArray12unsafe__blitGbE(dst, dst_offset, src, src_offset, len) {
  _M0MPC15array10FixedArray12unsafe__blitGRPB17UnsafeMaybeUninitGbEE(dst, dst_offset, src, src_offset, len);
}
function _M0MPB18UninitializedArray23unsafe__make__and__blitGyE(src, allocate_len, src_offset, dst_offset, blit_len) {
  const dst = new Uint8Array(allocate_len);
  _M0MPB18UninitializedArray12unsafe__blitGyE(dst, dst_offset, src, src_offset, blit_len);
  return dst;
}
function _M0MPB18UninitializedArray23unsafe__make__and__blitGcE(src, allocate_len, src_offset, dst_offset, blit_len) {
  const dst = new Array(allocate_len);
  _M0MPB18UninitializedArray12unsafe__blitGcE(dst, dst_offset, src, src_offset, blit_len);
  return dst;
}
function _M0MPB18UninitializedArray23unsafe__make__and__blitGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(src, allocate_len, src_offset, dst_offset, blit_len) {
  const dst = new Array(allocate_len);
  _M0MPB18UninitializedArray12unsafe__blitGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(dst, dst_offset, src, src_offset, blit_len);
  return dst;
}
function _M0MPB18UninitializedArray23unsafe__make__and__blitGiE(src, allocate_len, src_offset, dst_offset, blit_len) {
  const dst = new Array(allocate_len);
  _M0MPB18UninitializedArray12unsafe__blitGiE(dst, dst_offset, src, src_offset, blit_len);
  return dst;
}
function _M0MPB18UninitializedArray23unsafe__make__and__blitGbE(src, allocate_len, src_offset, dst_offset, blit_len) {
  const dst = new Array(allocate_len);
  _M0MPB18UninitializedArray12unsafe__blitGbE(dst, dst_offset, src, src_offset, blit_len);
  return dst;
}
function _M0MPB13StringBuilder13write__objectGiE(self, obj) {
  _M0IP016_24default__implPB4Show6outputGiE(obj, { self: self, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
}
function _M0MPB18UninitializedArray23make__and__blit_2einnerGyE(src, allocate_len, len, src_offset, dst_offset) {
  let _tmp;
  if (allocate_len >= 0) {
    let _tmp$2;
    if (len >= 0) {
      let _tmp$3;
      const _p = src.length;
      if (src_offset >= 0 && src_offset <= (_p - len | 0)) {
        _tmp$3 = dst_offset >= 0 && dst_offset <= (allocate_len - len | 0);
      } else {
        _tmp$3 = false;
      }
      _tmp$2 = _tmp$3;
    } else {
      _tmp$2 = false;
    }
    _tmp = _tmp$2;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    return _M0MPB18UninitializedArray23unsafe__make__and__blitGyE(src, allocate_len, src_offset, dst_offset, len);
  } else {
    const _string_builder = _M0MPB13StringBuilder21StringBuilder_2einner(8);
    const _p = "bounds check failed: allocate_len = ";
    _string_builder.val = `${_string_builder.val}${_p}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, allocate_len);
    const _p$2 = ", src_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$2}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src_offset);
    const _p$3 = ", dst_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$3}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, dst_offset);
    const _p$4 = ", len = ";
    _string_builder.val = `${_string_builder.val}${_p$4}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, len);
    const _p$5 = ", src.length = ";
    _string_builder.val = `${_string_builder.val}${_p$5}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src.length);
    return $panic(_string_builder.val);
  }
}
function _M0MPB18UninitializedArray23make__and__blit_2einnerGcE(src, allocate_len, len, src_offset, dst_offset) {
  let _tmp;
  if (allocate_len >= 0) {
    let _tmp$2;
    if (len >= 0) {
      let _tmp$3;
      const _p = src.length;
      if (src_offset >= 0 && src_offset <= (_p - len | 0)) {
        _tmp$3 = dst_offset >= 0 && dst_offset <= (allocate_len - len | 0);
      } else {
        _tmp$3 = false;
      }
      _tmp$2 = _tmp$3;
    } else {
      _tmp$2 = false;
    }
    _tmp = _tmp$2;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    return _M0MPB18UninitializedArray23unsafe__make__and__blitGcE(src, allocate_len, src_offset, dst_offset, len);
  } else {
    const _string_builder = _M0MPB13StringBuilder21StringBuilder_2einner(8);
    const _p = "bounds check failed: allocate_len = ";
    _string_builder.val = `${_string_builder.val}${_p}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, allocate_len);
    const _p$2 = ", src_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$2}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src_offset);
    const _p$3 = ", dst_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$3}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, dst_offset);
    const _p$4 = ", len = ";
    _string_builder.val = `${_string_builder.val}${_p$4}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, len);
    const _p$5 = ", src.length = ";
    _string_builder.val = `${_string_builder.val}${_p$5}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src.length);
    return $panic(_string_builder.val);
  }
}
function _M0MPB18UninitializedArray23make__and__blit_2einnerGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(src, allocate_len, len, src_offset, dst_offset) {
  let _tmp;
  if (allocate_len >= 0) {
    let _tmp$2;
    if (len >= 0) {
      let _tmp$3;
      const _p = src.length;
      if (src_offset >= 0 && src_offset <= (_p - len | 0)) {
        _tmp$3 = dst_offset >= 0 && dst_offset <= (allocate_len - len | 0);
      } else {
        _tmp$3 = false;
      }
      _tmp$2 = _tmp$3;
    } else {
      _tmp$2 = false;
    }
    _tmp = _tmp$2;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    return _M0MPB18UninitializedArray23unsafe__make__and__blitGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(src, allocate_len, src_offset, dst_offset, len);
  } else {
    const _string_builder = _M0MPB13StringBuilder21StringBuilder_2einner(8);
    const _p = "bounds check failed: allocate_len = ";
    _string_builder.val = `${_string_builder.val}${_p}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, allocate_len);
    const _p$2 = ", src_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$2}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src_offset);
    const _p$3 = ", dst_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$3}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, dst_offset);
    const _p$4 = ", len = ";
    _string_builder.val = `${_string_builder.val}${_p$4}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, len);
    const _p$5 = ", src.length = ";
    _string_builder.val = `${_string_builder.val}${_p$5}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src.length);
    return $panic(_string_builder.val);
  }
}
function _M0MPB18UninitializedArray23make__and__blit_2einnerGiE(src, allocate_len, len, src_offset, dst_offset) {
  let _tmp;
  if (allocate_len >= 0) {
    let _tmp$2;
    if (len >= 0) {
      let _tmp$3;
      const _p = src.length;
      if (src_offset >= 0 && src_offset <= (_p - len | 0)) {
        _tmp$3 = dst_offset >= 0 && dst_offset <= (allocate_len - len | 0);
      } else {
        _tmp$3 = false;
      }
      _tmp$2 = _tmp$3;
    } else {
      _tmp$2 = false;
    }
    _tmp = _tmp$2;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    return _M0MPB18UninitializedArray23unsafe__make__and__blitGiE(src, allocate_len, src_offset, dst_offset, len);
  } else {
    const _string_builder = _M0MPB13StringBuilder21StringBuilder_2einner(8);
    const _p = "bounds check failed: allocate_len = ";
    _string_builder.val = `${_string_builder.val}${_p}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, allocate_len);
    const _p$2 = ", src_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$2}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src_offset);
    const _p$3 = ", dst_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$3}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, dst_offset);
    const _p$4 = ", len = ";
    _string_builder.val = `${_string_builder.val}${_p$4}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, len);
    const _p$5 = ", src.length = ";
    _string_builder.val = `${_string_builder.val}${_p$5}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src.length);
    return $panic(_string_builder.val);
  }
}
function _M0MPB18UninitializedArray23make__and__blit_2einnerGbE(src, allocate_len, len, src_offset, dst_offset) {
  let _tmp;
  if (allocate_len >= 0) {
    let _tmp$2;
    if (len >= 0) {
      let _tmp$3;
      const _p = src.length;
      if (src_offset >= 0 && src_offset <= (_p - len | 0)) {
        _tmp$3 = dst_offset >= 0 && dst_offset <= (allocate_len - len | 0);
      } else {
        _tmp$3 = false;
      }
      _tmp$2 = _tmp$3;
    } else {
      _tmp$2 = false;
    }
    _tmp = _tmp$2;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    return _M0MPB18UninitializedArray23unsafe__make__and__blitGbE(src, allocate_len, src_offset, dst_offset, len);
  } else {
    const _string_builder = _M0MPB13StringBuilder21StringBuilder_2einner(8);
    const _p = "bounds check failed: allocate_len = ";
    _string_builder.val = `${_string_builder.val}${_p}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, allocate_len);
    const _p$2 = ", src_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$2}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src_offset);
    const _p$3 = ", dst_offset = ";
    _string_builder.val = `${_string_builder.val}${_p$3}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, dst_offset);
    const _p$4 = ", len = ";
    _string_builder.val = `${_string_builder.val}${_p$4}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, len);
    const _p$5 = ", src.length = ";
    _string_builder.val = `${_string_builder.val}${_p$5}`;
    _M0MPB13StringBuilder13write__objectGiE(_string_builder, src.length);
    return $panic(_string_builder.val);
  }
}
function _M0MPB13StringBuilder21StringBuilder_2einner(capacity) {
  return capacity >= 0 ? new _M0TPB13StringBuilder("") : $panic("capacity must be non-negative");
}
function _M0IPB13StringBuilderPB6Logger11write__char(self, ch) {
  self.val = `${self.val}${String.fromCodePoint(ch)}`;
}
function _M0IPB13StringBuilderPB6Logger13write__string(self, str) {
  self.val = `${self.val}${str}`;
}
function _M0IP016_24default__implPB6Logger28write__string__interpolationGRPB13StringBuilderE(self, show) {
  show.method_table.method_0(show.self, { self: self, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
}
function _M0IP016_24default__implPB6Logger5writeGRPB13StringBuilderE(self, show) {
  show.method_table.method_0(show.self, { self: self, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
}
function _M0MPC16string6String21clamped__view_2einner(self, start, end) {
  const len = self.length;
  let lo;
  if (start <= 0) {
    lo = 0;
  } else {
    if (start >= len) {
      lo = len;
    } else {
      let _tmp;
      const _p = self.charCodeAt(start);
      if (_p >= 56320 && _p <= 57343) {
        const _p$2 = self.charCodeAt(start - 1 | 0);
        _tmp = _p$2 >= 55296 && _p$2 <= 56319;
      } else {
        _tmp = false;
      }
      if (_tmp) {
        lo = start + 1 | 0;
      } else {
        lo = start;
      }
    }
  }
  let hi;
  if (end === undefined) {
    hi = len;
  } else {
    const _Some = end;
    const _e = _Some;
    if (_e <= 0) {
      hi = 0;
    } else {
      if (_e >= len) {
        hi = len;
      } else {
        let _tmp;
        const _p = self.charCodeAt(_e);
        if (_p >= 56320 && _p <= 57343) {
          const _p$2 = self.charCodeAt(_e - 1 | 0);
          _tmp = _p$2 >= 55296 && _p$2 <= 56319;
        } else {
          _tmp = false;
        }
        if (_tmp) {
          hi = _e - 1 | 0;
        } else {
          hi = _e;
        }
      }
    }
  }
  return lo >= hi ? new _M0TPC16string10StringView(self, lo, lo) : new _M0TPC16string10StringView(self, lo, hi);
}
function _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(self, value, start, len) {
  _M0IPB13StringBuilderPB6Logger11write__view(self, _M0MPC16string6String21clamped__view_2einner(value, start, start + len | 0));
}
function _M0IP016_24default__implPB4Show6outputGiE(self, logger) {
  logger.method_table.method_0(logger.self, _M0IPC13int3IntPB4Show10to__string(self));
}
function _M0MPC13int3Int18to__string_2einner(self, radix) {
  return _M0FPB19int__to__string__js(self, radix);
}
function _M0MPC16string10StringView9to__owned(self) {
  return self.str.substring(self.start, self.end);
}
function _M0IPB13StringBuilderPB6Logger11write__view(self, str) {
  self.val = `${self.val}${_M0MPC16string10StringView9to__owned(str)}`;
}
function _M0MPC15array5Array13Array_2einnerGcE(capacity) {
  return capacity >= 0 ? (capacity === 0 ? new _M0TPB5ArrayGcE([], 0) : new _M0TPB5ArrayGcE(new Array(capacity), 0)) : $panic("capacity must be non-negative");
}
function _M0FPB23array__growth__capacity(current, len, required) {
  if (required < len) {
    $panic("Array capacity overflow");
  }
  const start = current === 0 ? 8 : current;
  let _tmp = start;
  while (true) {
    const space = _tmp;
    if (space < required) {
      const next = Math.imul(space, 2) | 0;
      if (next <= space) {
        return required;
      }
      _tmp = next;
      continue;
    } else {
      return space;
    }
  }
}
function _M0MPC15array5Array8capacityGyE(self) {
  return self.buf.length;
}
function _M0MPC15array5Array8capacityGcE(self) {
  return self.buf.length;
}
function _M0MPC15array5Array8capacityGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(self) {
  return self.buf.length;
}
function _M0MPC15array5Array8capacityGiE(self) {
  return self.buf.length;
}
function _M0MPC15array5Array8capacityGbE(self) {
  return self.buf.length;
}
function _M0MPC15array5Array14resize__bufferGyE(self, new_capacity) {
  const old_buf = self.buf;
  self.buf = new Uint8Array([]);
  const len = self.len;
  const copy_len = len < new_capacity ? len : new_capacity;
  const new_buf = _M0MPB18UninitializedArray23make__and__blit_2einnerGyE(old_buf, new_capacity, copy_len, 0, 0);
  self.buf = new_buf;
}
function _M0MPC15array5Array14resize__bufferGcE(self, new_capacity) {
  const old_buf = self.buf;
  self.buf = [];
  const len = self.len;
  const copy_len = len < new_capacity ? len : new_capacity;
  const new_buf = _M0MPB18UninitializedArray23make__and__blit_2einnerGcE(old_buf, new_capacity, copy_len, 0, 0);
  self.buf = new_buf;
}
function _M0MPC15array5Array14resize__bufferGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(self, new_capacity) {
  const old_buf = self.buf;
  self.buf = [];
  const len = self.len;
  const copy_len = len < new_capacity ? len : new_capacity;
  const new_buf = _M0MPB18UninitializedArray23make__and__blit_2einnerGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(old_buf, new_capacity, copy_len, 0, 0);
  self.buf = new_buf;
}
function _M0MPC15array5Array14resize__bufferGiE(self, new_capacity) {
  const old_buf = self.buf;
  self.buf = [];
  const len = self.len;
  const copy_len = len < new_capacity ? len : new_capacity;
  const new_buf = _M0MPB18UninitializedArray23make__and__blit_2einnerGiE(old_buf, new_capacity, copy_len, 0, 0);
  self.buf = new_buf;
}
function _M0MPC15array5Array14resize__bufferGbE(self, new_capacity) {
  const old_buf = self.buf;
  self.buf = [];
  const len = self.len;
  const copy_len = len < new_capacity ? len : new_capacity;
  const new_buf = _M0MPB18UninitializedArray23make__and__blit_2einnerGbE(old_buf, new_capacity, copy_len, 0, 0);
  self.buf = new_buf;
}
function _M0MPC15array5Array7reallocGyE(self, required) {
  const old_cap = _M0MPC15array5Array8capacityGyE(self);
  const new_cap = _M0FPB23array__growth__capacity(old_cap, self.len, required);
  _M0MPC15array5Array14resize__bufferGyE(self, new_cap);
}
function _M0MPC15array5Array7reallocGcE(self, required) {
  const old_cap = _M0MPC15array5Array8capacityGcE(self);
  const new_cap = _M0FPB23array__growth__capacity(old_cap, self.len, required);
  _M0MPC15array5Array14resize__bufferGcE(self, new_cap);
}
function _M0MPC15array5Array7reallocGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(self, required) {
  const old_cap = _M0MPC15array5Array8capacityGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(self);
  const new_cap = _M0FPB23array__growth__capacity(old_cap, self.len, required);
  _M0MPC15array5Array14resize__bufferGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(self, new_cap);
}
function _M0MPC15array5Array7reallocGiE(self, required) {
  const old_cap = _M0MPC15array5Array8capacityGiE(self);
  const new_cap = _M0FPB23array__growth__capacity(old_cap, self.len, required);
  _M0MPC15array5Array14resize__bufferGiE(self, new_cap);
}
function _M0MPC15array5Array7reallocGbE(self, required) {
  const old_cap = _M0MPC15array5Array8capacityGbE(self);
  const new_cap = _M0FPB23array__growth__capacity(old_cap, self.len, required);
  _M0MPC15array5Array14resize__bufferGbE(self, new_cap);
}
function _M0MPC15array5Array4pushGyE(self, value) {
  if (self.len === self.buf.length) {
    _M0MPC15array5Array7reallocGyE(self, self.len + 1 | 0);
  }
  const length = self.len;
  self.buf[length] = value;
  self.len = length + 1 | 0;
}
function _M0MPC15array5Array4pushGcE(self, value) {
  if (self.len === self.buf.length) {
    _M0MPC15array5Array7reallocGcE(self, self.len + 1 | 0);
  }
  const length = self.len;
  self.buf[length] = value;
  self.len = length + 1 | 0;
}
function _M0MPC15array5Array4pushGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(self, value) {
  if (self.len === self.buf.length) {
    _M0MPC15array5Array7reallocGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(self, self.len + 1 | 0);
  }
  const length = self.len;
  self.buf[length] = value;
  self.len = length + 1 | 0;
}
function _M0MPC15array5Array4pushGiE(self, value) {
  if (self.len === self.buf.length) {
    _M0MPC15array5Array7reallocGiE(self, self.len + 1 | 0);
  }
  const length = self.len;
  self.buf[length] = value;
  self.len = length + 1 | 0;
}
function _M0MPC15array5Array4pushGbE(self, value) {
  if (self.len === self.buf.length) {
    _M0MPC15array5Array7reallocGbE(self, self.len + 1 | 0);
  }
  const length = self.len;
  self.buf[length] = value;
  self.len = length + 1 | 0;
}
function _M0IPC14char4CharPB4Show10to__string(self) {
  return String.fromCodePoint(self);
}
function _M0MPC16string6String9to__array(self) {
  const chars = _M0MPC15array5Array13Array_2einnerGcE(self.length);
  const _bind = self.length;
  let _tmp = 0;
  while (true) {
    const _string_index = _tmp;
    if (_string_index < _bind) {
      let _decoded_next_string_index;
      let _decoded_char;
      _L: {
        const _bind$2 = self.charCodeAt(_string_index);
        if (_bind$2 >= 55296 && _bind$2 <= 56319 && (_string_index + 1 | 0) < _bind) {
          const _bind$3 = self.charCodeAt(_string_index + 1 | 0);
          if (_bind$3 >= 56320 && _bind$3 <= 57343) {
            const _tmp$2 = _string_index + 2 | 0;
            const _p = (((Math.imul(_bind$2 - 55296 | 0, 1024) | 0) + _bind$3 | 0) - 56320 | 0) + 65536 | 0;
            _decoded_next_string_index = _tmp$2;
            _decoded_char = _p;
            break _L;
          } else {
            const _tmp$2 = _string_index + 1 | 0;
            const _p = _bind$2;
            _decoded_next_string_index = _tmp$2;
            _decoded_char = _p;
            break _L;
          }
        } else {
          const _tmp$2 = _string_index + 1 | 0;
          const _p = _bind$2;
          _decoded_next_string_index = _tmp$2;
          _decoded_char = _p;
          break _L;
        }
      }
      _M0MPC15array5Array4pushGcE(chars, _decoded_char);
      _tmp = _decoded_next_string_index;
      continue;
    } else {
      break;
    }
  }
  return chars;
}
function _M0IPC13int3IntPB4Show10to__string(self) {
  return _M0MPC13int3Int18to__string_2einner(self, 10);
}
function _M0MPC15array5Array20unsafe__make__uninitGyE(len) {
  return new _M0TPB5ArrayGyE(new Uint8Array(len), len);
}
function _M0MPC15array5Array20unsafe__make__uninitGiE(len) {
  return new _M0TPB5ArrayGiE(new Array(len), len);
}
function _M0MPC15array5Array20unsafe__make__uninitGbE(len) {
  return new _M0TPB5ArrayGbE(new Array(len), len);
}
function _M0MPC13int3Int8to__char(self) {
  _L: {
    if (self >= 0 && self <= 55295) {
      break _L;
    } else {
      if (self >= 57344 && self <= 1114111) {
        break _L;
      } else {
        return -1;
      }
    }
  }
  return self;
}
function _M0MPC15bytes5Bytes11from__array(arr) {
  const len = arr.end - arr.start | 0;
  if (len === 0) {
    return $bytes_literal$0;
  }
  const result = _M0MPB18UninitializedArray23unsafe__make__and__blitGyE(arr.buf, len, arr.start, 0, len);
  return result;
}
function _M0MPC15array5Array4makeGyE(len, elem) {
  const arr = _M0MPC15array5Array20unsafe__make__uninitGyE(len);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < len) {
      arr.buf[i] = elem;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return arr;
}
function _M0MPC15array5Array4makeGiE(len, elem) {
  const arr = _M0MPC15array5Array20unsafe__make__uninitGiE(len);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < len) {
      arr.buf[i] = elem;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return arr;
}
function _M0MPC15array5Array4makeGbE(len, elem) {
  const arr = _M0MPC15array5Array20unsafe__make__uninitGbE(len);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < len) {
      arr.buf[i] = elem;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return arr;
}
function _M0MPC15array5Array3popGiE(self) {
  const len = self.len;
  if (len === 0) {
    return undefined;
  } else {
    const index = len - 1 | 0;
    const v = self.buf[index];
    self.len = index;
    return v;
  }
}
function _M0FPC28encoding4utf814encode_2einner(str, bom) {
  return _M0FPC28encoding4utf816encode__utf8__js(str.str, str.start, str.end - str.start | 0, bom);
}
function _M0FPC28encoding4utf821utf8__find__malformed(src, src_offset, src_length) {
  const _bind = src_offset + src_length | 0;
  const _bind$2 = src.length;
  const _bind$3 = src_offset < 0 ? 0 : src_offset > _bind$2 ? _bind$2 : src_offset;
  const _bind$4 = _bind < 0 ? 0 : _bind > _bind$2 ? _bind$2 : _bind;
  const view = new _M0TPC15bytes9BytesView(src, _bind$3, _bind$4 > _bind$3 ? _bind$4 : _bind$3);
  let _tmp = view;
  while (true) {
    const bytes = _tmp;
    let malformed;
    _L: {
      let rest;
      _L$2: {
        let rest$2;
        _L$3: {
          let rest$3;
          _L$4: {
            let rest$4;
            _L$5: {
              if ((bytes.end - bytes.start | 0) === 0) {
                return -1;
              } else {
                if ((bytes.end - bytes.start | 0) >= 8) {
                  const _x = bytes.buf[bytes.start];
                  if (_x <= 127) {
                    const _x$2 = bytes.buf[bytes.start + 1 | 0];
                    if (_x$2 <= 127) {
                      const _x$3 = bytes.buf[bytes.start + 2 | 0];
                      if (_x$3 <= 127) {
                        const _x$4 = bytes.buf[bytes.start + 3 | 0];
                        if (_x$4 <= 127) {
                          const _x$5 = bytes.buf[bytes.start + 4 | 0];
                          if (_x$5 <= 127) {
                            const _x$6 = bytes.buf[bytes.start + 5 | 0];
                            if (_x$6 <= 127) {
                              const _x$7 = bytes.buf[bytes.start + 6 | 0];
                              if (_x$7 <= 127) {
                                const _x$8 = bytes.buf[bytes.start + 7 | 0];
                                if (_x$8 <= 127) {
                                  const _x$9 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 8 | 0, bytes.end);
                                  _tmp = _x$9;
                                  continue;
                                } else {
                                  const _x$9 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 1 | 0, bytes.end);
                                  rest$4 = _x$9;
                                  break _L$5;
                                }
                              } else {
                                const _x$8 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 1 | 0, bytes.end);
                                rest$4 = _x$8;
                                break _L$5;
                              }
                            } else {
                              const _x$7 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 1 | 0, bytes.end);
                              rest$4 = _x$7;
                              break _L$5;
                            }
                          } else {
                            const _x$6 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 1 | 0, bytes.end);
                            rest$4 = _x$6;
                            break _L$5;
                          }
                        } else {
                          const _x$5 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 1 | 0, bytes.end);
                          rest$4 = _x$5;
                          break _L$5;
                        }
                      } else {
                        const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 1 | 0, bytes.end);
                        rest$4 = _x$4;
                        break _L$5;
                      }
                    } else {
                      const _x$3 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 1 | 0, bytes.end);
                      rest$4 = _x$3;
                      break _L$5;
                    }
                  } else {
                    if (_x >= 194 && _x <= 223) {
                      const _x$2 = bytes.buf[bytes.start + 1 | 0];
                      if (_x$2 >= 128 && _x$2 <= 191) {
                        const _x$3 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 2 | 0, bytes.end);
                        rest$3 = _x$3;
                        break _L$4;
                      } else {
                        malformed = bytes;
                        break _L;
                      }
                    } else {
                      if (_x === 224) {
                        const _x$2 = bytes.buf[bytes.start + 1 | 0];
                        if (_x$2 >= 160 && _x$2 <= 191) {
                          const _x$3 = bytes.buf[bytes.start + 2 | 0];
                          if (_x$3 >= 128 && _x$3 <= 191) {
                            const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
                            rest$2 = _x$4;
                            break _L$3;
                          } else {
                            malformed = bytes;
                            break _L;
                          }
                        } else {
                          malformed = bytes;
                          break _L;
                        }
                      } else {
                        if (_x >= 225 && _x <= 236) {
                          const _x$2 = bytes.buf[bytes.start + 1 | 0];
                          if (_x$2 >= 128 && _x$2 <= 191) {
                            const _x$3 = bytes.buf[bytes.start + 2 | 0];
                            if (_x$3 >= 128 && _x$3 <= 191) {
                              const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
                              rest$2 = _x$4;
                              break _L$3;
                            } else {
                              malformed = bytes;
                              break _L;
                            }
                          } else {
                            malformed = bytes;
                            break _L;
                          }
                        } else {
                          if (_x === 237) {
                            const _x$2 = bytes.buf[bytes.start + 1 | 0];
                            if (_x$2 >= 128 && _x$2 <= 159) {
                              const _x$3 = bytes.buf[bytes.start + 2 | 0];
                              if (_x$3 >= 128 && _x$3 <= 191) {
                                const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
                                rest$2 = _x$4;
                                break _L$3;
                              } else {
                                malformed = bytes;
                                break _L;
                              }
                            } else {
                              malformed = bytes;
                              break _L;
                            }
                          } else {
                            if (_x >= 238 && _x <= 239) {
                              const _x$2 = bytes.buf[bytes.start + 1 | 0];
                              if (_x$2 >= 128 && _x$2 <= 191) {
                                const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                if (_x$3 >= 128 && _x$3 <= 191) {
                                  const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
                                  rest$2 = _x$4;
                                  break _L$3;
                                } else {
                                  malformed = bytes;
                                  break _L;
                                }
                              } else {
                                malformed = bytes;
                                break _L;
                              }
                            } else {
                              if (_x === 240) {
                                const _x$2 = bytes.buf[bytes.start + 1 | 0];
                                if (_x$2 >= 144 && _x$2 <= 191) {
                                  const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                  if (_x$3 >= 128 && _x$3 <= 191) {
                                    const _x$4 = bytes.buf[bytes.start + 3 | 0];
                                    if (_x$4 >= 128 && _x$4 <= 191) {
                                      const _x$5 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 4 | 0, bytes.end);
                                      rest = _x$5;
                                      break _L$2;
                                    } else {
                                      malformed = bytes;
                                      break _L;
                                    }
                                  } else {
                                    malformed = bytes;
                                    break _L;
                                  }
                                } else {
                                  malformed = bytes;
                                  break _L;
                                }
                              } else {
                                if (_x >= 241 && _x <= 243) {
                                  const _x$2 = bytes.buf[bytes.start + 1 | 0];
                                  if (_x$2 >= 128 && _x$2 <= 191) {
                                    const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                    if (_x$3 >= 128 && _x$3 <= 191) {
                                      const _x$4 = bytes.buf[bytes.start + 3 | 0];
                                      if (_x$4 >= 128 && _x$4 <= 191) {
                                        const _x$5 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 4 | 0, bytes.end);
                                        rest = _x$5;
                                        break _L$2;
                                      } else {
                                        malformed = bytes;
                                        break _L;
                                      }
                                    } else {
                                      malformed = bytes;
                                      break _L;
                                    }
                                  } else {
                                    malformed = bytes;
                                    break _L;
                                  }
                                } else {
                                  if (_x === 244) {
                                    const _x$2 = bytes.buf[bytes.start + 1 | 0];
                                    if (_x$2 >= 128 && _x$2 <= 143) {
                                      const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                      if (_x$3 >= 128 && _x$3 <= 191) {
                                        const _x$4 = bytes.buf[bytes.start + 3 | 0];
                                        if (_x$4 >= 128 && _x$4 <= 191) {
                                          const _x$5 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 4 | 0, bytes.end);
                                          rest = _x$5;
                                          break _L$2;
                                        } else {
                                          malformed = bytes;
                                          break _L;
                                        }
                                      } else {
                                        malformed = bytes;
                                        break _L;
                                      }
                                    } else {
                                      malformed = bytes;
                                      break _L;
                                    }
                                  } else {
                                    malformed = bytes;
                                    break _L;
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                } else {
                  const _x = bytes.buf[bytes.start];
                  if (_x >= 0 && _x <= 127) {
                    const _x$2 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 1 | 0, bytes.end);
                    rest$4 = _x$2;
                    break _L$5;
                  } else {
                    if ((bytes.end - bytes.start | 0) >= 2) {
                      if (_x >= 194 && _x <= 223) {
                        const _x$2 = bytes.buf[bytes.start + 1 | 0];
                        if (_x$2 >= 128 && _x$2 <= 191) {
                          const _x$3 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 2 | 0, bytes.end);
                          rest$3 = _x$3;
                          break _L$4;
                        } else {
                          malformed = bytes;
                          break _L;
                        }
                      } else {
                        if ((bytes.end - bytes.start | 0) >= 3) {
                          if (_x === 224) {
                            const _x$2 = bytes.buf[bytes.start + 1 | 0];
                            if (_x$2 >= 160 && _x$2 <= 191) {
                              const _x$3 = bytes.buf[bytes.start + 2 | 0];
                              if (_x$3 >= 128 && _x$3 <= 191) {
                                const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
                                rest$2 = _x$4;
                                break _L$3;
                              } else {
                                malformed = bytes;
                                break _L;
                              }
                            } else {
                              malformed = bytes;
                              break _L;
                            }
                          } else {
                            if (_x >= 225 && _x <= 236) {
                              const _x$2 = bytes.buf[bytes.start + 1 | 0];
                              if (_x$2 >= 128 && _x$2 <= 191) {
                                const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                if (_x$3 >= 128 && _x$3 <= 191) {
                                  const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
                                  rest$2 = _x$4;
                                  break _L$3;
                                } else {
                                  malformed = bytes;
                                  break _L;
                                }
                              } else {
                                malformed = bytes;
                                break _L;
                              }
                            } else {
                              if (_x === 237) {
                                const _x$2 = bytes.buf[bytes.start + 1 | 0];
                                if (_x$2 >= 128 && _x$2 <= 159) {
                                  const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                  if (_x$3 >= 128 && _x$3 <= 191) {
                                    const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
                                    rest$2 = _x$4;
                                    break _L$3;
                                  } else {
                                    malformed = bytes;
                                    break _L;
                                  }
                                } else {
                                  malformed = bytes;
                                  break _L;
                                }
                              } else {
                                if (_x >= 238 && _x <= 239) {
                                  const _x$2 = bytes.buf[bytes.start + 1 | 0];
                                  if (_x$2 >= 128 && _x$2 <= 191) {
                                    const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                    if (_x$3 >= 128 && _x$3 <= 191) {
                                      const _x$4 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
                                      rest$2 = _x$4;
                                      break _L$3;
                                    } else {
                                      malformed = bytes;
                                      break _L;
                                    }
                                  } else {
                                    malformed = bytes;
                                    break _L;
                                  }
                                } else {
                                  if ((bytes.end - bytes.start | 0) >= 4) {
                                    if (_x === 240) {
                                      const _x$2 = bytes.buf[bytes.start + 1 | 0];
                                      if (_x$2 >= 144 && _x$2 <= 191) {
                                        const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                        if (_x$3 >= 128 && _x$3 <= 191) {
                                          const _x$4 = bytes.buf[bytes.start + 3 | 0];
                                          if (_x$4 >= 128 && _x$4 <= 191) {
                                            const _x$5 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 4 | 0, bytes.end);
                                            rest = _x$5;
                                            break _L$2;
                                          } else {
                                            malformed = bytes;
                                            break _L;
                                          }
                                        } else {
                                          malformed = bytes;
                                          break _L;
                                        }
                                      } else {
                                        malformed = bytes;
                                        break _L;
                                      }
                                    } else {
                                      if (_x >= 241 && _x <= 243) {
                                        const _x$2 = bytes.buf[bytes.start + 1 | 0];
                                        if (_x$2 >= 128 && _x$2 <= 191) {
                                          const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                          if (_x$3 >= 128 && _x$3 <= 191) {
                                            const _x$4 = bytes.buf[bytes.start + 3 | 0];
                                            if (_x$4 >= 128 && _x$4 <= 191) {
                                              const _x$5 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 4 | 0, bytes.end);
                                              rest = _x$5;
                                              break _L$2;
                                            } else {
                                              malformed = bytes;
                                              break _L;
                                            }
                                          } else {
                                            malformed = bytes;
                                            break _L;
                                          }
                                        } else {
                                          malformed = bytes;
                                          break _L;
                                        }
                                      } else {
                                        if (_x === 244) {
                                          const _x$2 = bytes.buf[bytes.start + 1 | 0];
                                          if (_x$2 >= 128 && _x$2 <= 143) {
                                            const _x$3 = bytes.buf[bytes.start + 2 | 0];
                                            if (_x$3 >= 128 && _x$3 <= 191) {
                                              const _x$4 = bytes.buf[bytes.start + 3 | 0];
                                              if (_x$4 >= 128 && _x$4 <= 191) {
                                                const _x$5 = new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 4 | 0, bytes.end);
                                                rest = _x$5;
                                                break _L$2;
                                              } else {
                                                malformed = bytes;
                                                break _L;
                                              }
                                            } else {
                                              malformed = bytes;
                                              break _L;
                                            }
                                          } else {
                                            malformed = bytes;
                                            break _L;
                                          }
                                        } else {
                                          malformed = bytes;
                                          break _L;
                                        }
                                      }
                                    }
                                  } else {
                                    malformed = bytes;
                                    break _L;
                                  }
                                }
                              }
                            }
                          }
                        } else {
                          malformed = bytes;
                          break _L;
                        }
                      }
                    } else {
                      malformed = bytes;
                      break _L;
                    }
                  }
                }
              }
            }
            _tmp = rest$4;
            continue;
          }
          _tmp = rest$3;
          continue;
        }
        _tmp = rest$2;
        continue;
      }
      _tmp = rest;
      continue;
    }
    return malformed.start - src_offset | 0;
  }
}
function _M0FPC28encoding4utf825strict__malformed__suffix(bytes) {
  const input = bytes.buf;
  const src_offset = bytes.start;
  const src_length = bytes.end - bytes.start | 0;
  const malformed_offset = _M0FPC28encoding4utf821utf8__find__malformed(input, src_offset, src_length);
  const _bind = bytes.end - bytes.start | 0;
  const _bind$2 = malformed_offset < 0 ? 0 : malformed_offset > _bind ? _bind : malformed_offset;
  return new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + _bind$2 | 0, bytes.start + _bind | 0);
}
function _M0FPC28encoding4utf815drop__utf8__bom(bytes, ignore_bom) {
  _L: {
    if (ignore_bom) {
      _L$2: {
        if ((bytes.end - bytes.start | 0) >= 3) {
          const _x = bytes.buf[bytes.start];
          if (_x === 239) {
            const _x$2 = bytes.buf[bytes.start + 1 | 0];
            if (_x$2 === 187) {
              const _x$3 = bytes.buf[bytes.start + 2 | 0];
              if (_x$3 === 191) {
                return new _M0TPC15bytes9BytesView(bytes.buf, bytes.start + 3 | 0, bytes.end);
              } else {
                break _L$2;
              }
            } else {
              break _L$2;
            }
          } else {
            break _L$2;
          }
        } else {
          break _L$2;
        }
      }
      break _L;
    } else {
      break _L;
    }
  }
  return bytes;
}
function _M0FPC28encoding4utf814decode_2einner(bytes, ignore_bom) {
  const result = _M0FPC28encoding4utf816decode__utf8__js(bytes.buf, bytes.start, bytes.end - bytes.start | 0, !ignore_bom);
  if (result.length === 1) {
    return new _M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE2Ok(0 >>> 0 < result.length ? result[0] : $oob());
  } else {
    const bytes$2 = _M0FPC28encoding4utf815drop__utf8__bom(bytes, ignore_bom);
    return new _M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE3Err(new _M0DTPC15error5Error60moonbitlang_2fcore_2fencoding_2futf8_2eMalformed_2eMalformed(_M0FPC28encoding4utf825strict__malformed__suffix(bytes$2)));
  }
}
function _M0MPC13ref3Ref3RefGiE(x) {
  return new _M0TPC13ref3RefGiE(x);
}
function _M0FP37walkzzz12image_2ecore10safe__math12clamp__coord(v, max_val) {
  return v < 0 ? 0 : v >= max_val ? max_val - 1 | 0 : v;
}
function _M0FP37walkzzz12image_2ecore10safe__math11clamp__byte(v) {
  return (v < 0 ? 0 : v > 255 ? 255 : v) & 255;
}
function _M0FP37walkzzz13image_2ecodec4util12crc32__table() {
  const table = _M0MPC15array5Array4makeGiE(256, 0);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < 256) {
      let crc = i;
      let _tmp$2 = 0;
      while (true) {
        const _ = _tmp$2;
        if (_ < 8) {
          crc = (crc & 1) !== 0 ? crc >> 1 & 2147483647 ^ -306674912 : crc >> 1 & 2147483647;
          _tmp$2 = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _bind = crc;
      if (i < 0 || i >= table.len) {
        $panic();
      }
      table.buf[i] = _bind;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return table;
}
function _M0FP37walkzzz13image_2ecodec4util5crc32(data) {
  const table = _M0FP37walkzzz13image_2ecodec4util12crc32__table();
  let crc = -1;
  const _bind = data.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      const _tmp$2 = crc >> 8 & 16777215;
      const _bind$2 = (crc ^ (i >>> 0 < data.length ? data[i] : $oob())) & 255;
      if (_bind$2 < 0 || _bind$2 >= table.len) {
        $panic();
      }
      crc = _tmp$2 ^ table.buf[_bind$2];
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return crc ^ -1;
}
function _M0FP37walkzzz13image_2ecodec4util7adler32(data) {
  let a = 1;
  let b = 0;
  const _bind = data.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      a = (a + (i >>> 0 < data.length ? data[i] : $oob()) | 0) % 65521 | 0;
      b = (b + a | 0) % 65521 | 0;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return b << 16 | a;
}
function _M0FP37walkzzz13image_2ecodec5codec16is__webp__format(data) {
  const len = data.length;
  if (len < 12) {
    return false;
  }
  if ((0 >>> 0 < data.length ? data[0] : $oob()) !== 82 || ((1 >>> 0 < data.length ? data[1] : $oob()) !== 73 || ((2 >>> 0 < data.length ? data[2] : $oob()) !== 70 || (3 >>> 0 < data.length ? data[3] : $oob()) !== 70))) {
    return false;
  }
  return (8 >>> 0 < data.length ? data[8] : $oob()) === 87 && ((9 >>> 0 < data.length ? data[9] : $oob()) === 69 && ((10 >>> 0 < data.length ? data[10] : $oob()) === 66 && (11 >>> 0 < data.length ? data[11] : $oob()) === 80));
}
function _M0FP37walkzzz13image_2ecodec5codec9read__4cc(data, offset) {
  const b0 = offset >>> 0 < data.length ? data[offset] : $oob();
  const _tmp = offset + 1 | 0;
  const b1 = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
  const _tmp$2 = offset + 2 | 0;
  const b2 = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
  const _tmp$3 = offset + 3 | 0;
  const b3 = _tmp$3 >>> 0 < data.length ? data[_tmp$3] : $oob();
  let s_buf = [b0, b1, b2, b3];
  let s_len = 4;
  const buf = new _M0TPB5ArrayGsE([], 0);
  const _bind = s_len;
  const _bind$2 = s_buf;
  let _tmp$4 = 0;
  while (true) {
    const _ = _tmp$4;
    if (_ < _bind) {
      const c = _bind$2[_];
      const _bind$3 = _M0MPC13int3Int8to__char(c);
      if (_bind$3 === -1) {
        _M0MPC15array5Array4pushGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(buf, "?");
      } else {
        const _Some = _bind$3;
        const _ch = _Some;
        _M0MPC15array5Array4pushGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(buf, _M0IPC14char4CharPB4Show10to__string(_ch));
      }
      _tmp$4 = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (0 >= buf.len) {
    $panic();
  }
  const _tmp$5 = buf.buf[0];
  if (1 >= buf.len) {
    $panic();
  }
  const _tmp$6 = buf.buf[1];
  if (2 >= buf.len) {
    $panic();
  }
  const _tmp$7 = buf.buf[2];
  if (3 >= buf.len) {
    $panic();
  }
  return `${_tmp$5}${_tmp$6}${_tmp$7}${buf.buf[3]}`;
}
function _M0FP37walkzzz13image_2ecodec5codec20webp__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec16is__webp__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16WebpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a WebP file"));
  }
  const len = data.length;
  let width = 0;
  let height = 0;
  let format = "unknown";
  let has_alpha = false;
  let has_animation = false;
  let has_icc_profile = false;
  let has_exif = false;
  let has_xmp = false;
  let pos = 12;
  while (true) {
    if ((pos + 8 | 0) <= len) {
      const chunk_id = _M0FP37walkzzz13image_2ecodec5codec9read__4cc(data, pos);
      const _tmp = pos + 4 | 0;
      const _tmp$2 = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      const _tmp$3 = pos + 5 | 0;
      const _tmp$4 = _tmp$2 | (_tmp$3 >>> 0 < data.length ? data[_tmp$3] : $oob()) << 8;
      const _tmp$5 = pos + 6 | 0;
      const _tmp$6 = _tmp$4 | (_tmp$5 >>> 0 < data.length ? data[_tmp$5] : $oob()) << 16;
      const _tmp$7 = pos + 7 | 0;
      const chunk_size = _tmp$6 | (_tmp$7 >>> 0 < data.length ? data[_tmp$7] : $oob()) << 24;
      if (chunk_size < 0 || ((pos + 8 | 0) + chunk_size | 0) > len) {
        break;
      }
      const chunk_data_start = pos + 8 | 0;
      switch (chunk_id) {
        case "VP8X": {
          format = "extended";
          if ((chunk_data_start + 10 | 0) <= len) {
            const flags = chunk_data_start >>> 0 < data.length ? data[chunk_data_start] : $oob();
            has_alpha = (flags & 16) !== 0;
            has_animation = (flags & 32) !== 0;
            has_icc_profile = (flags & 1) !== 0;
            has_exif = (flags & 8) !== 0;
            has_xmp = (flags & 4) !== 0;
            const _tmp$8 = chunk_data_start + 4 | 0;
            const _tmp$9 = _tmp$8 >>> 0 < data.length ? data[_tmp$8] : $oob();
            const _tmp$10 = chunk_data_start + 5 | 0;
            const _tmp$11 = _tmp$9 | (_tmp$10 >>> 0 < data.length ? data[_tmp$10] : $oob()) << 8;
            const _tmp$12 = chunk_data_start + 6 | 0;
            width = _tmp$11 | (_tmp$12 >>> 0 < data.length ? data[_tmp$12] : $oob()) << 16;
            width = width + 1 | 0;
            const _tmp$13 = chunk_data_start + 7 | 0;
            const _tmp$14 = _tmp$13 >>> 0 < data.length ? data[_tmp$13] : $oob();
            const _tmp$15 = chunk_data_start + 8 | 0;
            const _tmp$16 = _tmp$14 | (_tmp$15 >>> 0 < data.length ? data[_tmp$15] : $oob()) << 8;
            const _tmp$17 = chunk_data_start + 9 | 0;
            height = _tmp$16 | (_tmp$17 >>> 0 < data.length ? data[_tmp$17] : $oob()) << 16;
            height = height + 1 | 0;
          }
          break;
        }
        case "VP8 ": {
          const _p = format;
          const _p$2 = "extended";
          if (!(_p === _p$2)) {
            format = "lossy";
          }
          if ((chunk_data_start + 10 | 0) <= len && width === 0) {
            const _tmp$8 = chunk_data_start >>> 0 < data.length ? data[chunk_data_start] : $oob();
            const _tmp$9 = chunk_data_start + 1 | 0;
            const _tmp$10 = _tmp$8 | (_tmp$9 >>> 0 < data.length ? data[_tmp$9] : $oob()) << 8;
            const _tmp$11 = chunk_data_start + 2 | 0;
            const tag = _tmp$10 | (_tmp$11 >>> 0 < data.length ? data[_tmp$11] : $oob()) << 16;
            const is_keyframe = (tag & 1) === 0;
            if (is_keyframe) {
              if ((chunk_data_start + 9 | 0) <= len) {
                const _tmp$12 = chunk_data_start + 6 | 0;
                const _tmp$13 = _tmp$12 >>> 0 < data.length ? data[_tmp$12] : $oob();
                const _tmp$14 = chunk_data_start + 7 | 0;
                const w = _tmp$13 | (_tmp$14 >>> 0 < data.length ? data[_tmp$14] : $oob()) << 8;
                const _tmp$15 = chunk_data_start + 8 | 0;
                const _tmp$16 = _tmp$15 >>> 0 < data.length ? data[_tmp$15] : $oob();
                const _tmp$17 = chunk_data_start + 9 | 0;
                const h = _tmp$16 | (_tmp$17 >>> 0 < data.length ? data[_tmp$17] : $oob()) << 8;
                width = w & 16383;
                height = h & 16383;
              }
            }
          }
          break;
        }
        case "VP8L": {
          const _p$3 = format;
          const _p$4 = "extended";
          if (!(_p$3 === _p$4)) {
            format = "lossless";
          }
          if ((chunk_data_start + 5 | 0) <= len && width === 0) {
            if ((chunk_data_start >>> 0 < data.length ? data[chunk_data_start] : $oob()) === 47) {
              const _tmp$8 = chunk_data_start + 1 | 0;
              const b1 = _tmp$8 >>> 0 < data.length ? data[_tmp$8] : $oob();
              const _tmp$9 = chunk_data_start + 2 | 0;
              const b2 = _tmp$9 >>> 0 < data.length ? data[_tmp$9] : $oob();
              const _tmp$10 = chunk_data_start + 3 | 0;
              const b3 = _tmp$10 >>> 0 < data.length ? data[_tmp$10] : $oob();
              const _tmp$11 = chunk_data_start + 4 | 0;
              const b4 = _tmp$11 >>> 0 < data.length ? data[_tmp$11] : $oob();
              width = (b1 | (b2 & 63) << 8) + 1 | 0;
              height = (b2 >> 6 & 3 | b3 << 2 | (b4 & 15) << 10) + 1 | 0;
              const _p$5 = format;
              const _p$6 = "extended";
              if (!(_p$5 === _p$6)) {
                has_alpha = (b4 >> 4 & 1) === 1;
              }
            }
          }
          break;
        }
        case "ANIM": {
          has_animation = true;
          break;
        }
        case "ICCP": {
          has_icc_profile = true;
          break;
        }
        case "EXIF": {
          has_exif = true;
          break;
        }
        case "XMP ": {
          has_xmp = true;
          break;
        }
      }
      pos = pos + (8 + chunk_size | 0) | 0;
      if ((chunk_size % 2 | 0) === 1) {
        pos = pos + 1 | 0;
      }
      continue;
    } else {
      break;
    }
  }
  if (width === 0 || height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16WebpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("WebP: could not determine image dimensions"));
  }
  const num_channels = has_alpha ? 4 : 3;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16WebpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec16WebpInfoExtended(width, height, format, has_alpha, has_animation, has_icc_profile, has_exif, has_xmp, num_channels));
}
function _M0FP37walkzzz13image_2ecodec5codec21apng__channels__count(ct) {
  switch (ct) {
    case 0: {
      return 1;
    }
    case 2: {
      return 3;
    }
    case 3: {
      return 1;
    }
    case 4: {
      return 2;
    }
    case 6: {
      return 4;
    }
    default: {
      return 0;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec23apng__color__type__name(ct) {
  switch (ct) {
    case 0: {
      return "Grayscale";
    }
    case 2: {
      return "RGB";
    }
    case 3: {
      return "Palette";
    }
    case 4: {
      return "Grayscale+Alpha";
    }
    case 6: {
      return "RGBA";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec18is__png__signature(data, offset) {
  if ((offset + 8 | 0) > data.length) {
    return false;
  }
  if ((offset >>> 0 < data.length ? data[offset] : $oob()) === 137) {
    let _tmp;
    const _tmp$2 = offset + 1 | 0;
    if ((_tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob()) === 80) {
      let _tmp$3;
      const _tmp$4 = offset + 2 | 0;
      if ((_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob()) === 78) {
        let _tmp$5;
        const _tmp$6 = offset + 3 | 0;
        if ((_tmp$6 >>> 0 < data.length ? data[_tmp$6] : $oob()) === 71) {
          let _tmp$7;
          const _tmp$8 = offset + 4 | 0;
          if ((_tmp$8 >>> 0 < data.length ? data[_tmp$8] : $oob()) === 13) {
            let _tmp$9;
            const _tmp$10 = offset + 5 | 0;
            if ((_tmp$10 >>> 0 < data.length ? data[_tmp$10] : $oob()) === 10) {
              let _tmp$11;
              const _tmp$12 = offset + 6 | 0;
              if ((_tmp$12 >>> 0 < data.length ? data[_tmp$12] : $oob()) === 26) {
                const _tmp$13 = offset + 7 | 0;
                _tmp$11 = (_tmp$13 >>> 0 < data.length ? data[_tmp$13] : $oob()) === 10;
              } else {
                _tmp$11 = false;
              }
              _tmp$9 = _tmp$11;
            } else {
              _tmp$9 = false;
            }
            _tmp$7 = _tmp$9;
          } else {
            _tmp$7 = false;
          }
          _tmp$5 = _tmp$7;
        } else {
          _tmp$5 = false;
        }
        _tmp$3 = _tmp$5;
      } else {
        _tmp$3 = false;
      }
      _tmp = _tmp$3;
    } else {
      _tmp = false;
    }
    return _tmp;
  } else {
    return false;
  }
}
function _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, offset) {
  const _tmp = (offset >>> 0 < data.length ? data[offset] : $oob()) << 24;
  const _tmp$2 = offset + 1 | 0;
  const _tmp$3 = _tmp | (_tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob()) << 16;
  const _tmp$4 = offset + 2 | 0;
  const _tmp$5 = _tmp$3 | (_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob()) << 8;
  const _tmp$6 = offset + 3 | 0;
  return _tmp$5 | (_tmp$6 >>> 0 < data.length ? data[_tmp$6] : $oob());
}
function _M0FP37walkzzz13image_2ecodec5codec20apng__info__extended(data) {
  const len = data.length;
  if (len < 8) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16ApngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("APNG 数据过短"));
  }
  if (!_M0FP37walkzzz13image_2ecodec5codec18is__png__signature(data, 0)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16ApngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a PNG/APNG file"));
  }
  let pos = 8;
  let width = 0;
  let height = 0;
  let bit_depth = 0;
  let color_type = 0;
  let num_frames = 0;
  let num_plays = 0;
  let found_ihdr = false;
  while (true) {
    if ((pos + 8 | 0) <= len) {
      const chunk_len = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, pos);
      const _tmp = pos + 4 | 0;
      const b0 = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      const _tmp$2 = pos + 5 | 0;
      const b1 = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      const _tmp$3 = pos + 6 | 0;
      const b2 = _tmp$3 >>> 0 < data.length ? data[_tmp$3] : $oob();
      const _tmp$4 = pos + 7 | 0;
      const b3 = _tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob();
      if ((((pos + 8 | 0) + chunk_len | 0) + 4 | 0) > len) {
        break;
      }
      if (b0 === 73 && (b1 === 72 && (b2 === 68 && b3 === 82))) {
        width = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, pos + 8 | 0);
        height = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, pos + 12 | 0);
        const _tmp$5 = pos + 16 | 0;
        bit_depth = _tmp$5 >>> 0 < data.length ? data[_tmp$5] : $oob();
        const _tmp$6 = pos + 17 | 0;
        color_type = _tmp$6 >>> 0 < data.length ? data[_tmp$6] : $oob();
        found_ihdr = true;
      }
      if (b0 === 97 && (b1 === 99 && (b2 === 84 && b3 === 76))) {
        num_frames = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, pos + 8 | 0);
        num_plays = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, pos + 12 | 0);
      }
      pos = pos + ((8 + chunk_len | 0) + 4 | 0) | 0;
      continue;
    } else {
      break;
    }
  }
  if (!found_ihdr || (width === 0 || height === 0)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16ApngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("APNG IHDR 不存在或尺寸无效"));
  }
  const num_channels = _M0FP37walkzzz13image_2ecodec5codec21apng__channels__count(color_type);
  const has_alpha = color_type === 4 || color_type === 6;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16ApngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec16ApngInfoExtended(width, height, bit_depth, color_type, _M0FP37walkzzz13image_2ecodec5codec23apng__color__type__name(color_type), num_channels, has_alpha, num_frames, num_plays, num_frames > 1));
}
function _M0FP37walkzzz13image_2ecodec5codec16is__avif__format(data) {
  const len = data.length;
  if (len < 12) {
    return false;
  }
  if ((4 >>> 0 < data.length ? data[4] : $oob()) !== 102 || ((5 >>> 0 < data.length ? data[5] : $oob()) !== 116 || ((6 >>> 0 < data.length ? data[6] : $oob()) !== 121 || (7 >>> 0 < data.length ? data[7] : $oob()) !== 112))) {
    return false;
  }
  const b8 = 8 >>> 0 < data.length ? data[8] : $oob();
  const b9 = 9 >>> 0 < data.length ? data[9] : $oob();
  const b10 = 10 >>> 0 < data.length ? data[10] : $oob();
  const b11 = 11 >>> 0 < data.length ? data[11] : $oob();
  if (b8 === 97 && (b9 === 118 && (b10 === 105 && b11 === 102))) {
    return true;
  }
  if (b8 === 97 && (b9 === 118 && (b10 === 105 && b11 === 115))) {
    return true;
  }
  return false;
}
function _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, offset) {
  const _tmp = (offset >>> 0 < data.length ? data[offset] : $oob()) << 8;
  const _tmp$2 = offset + 1 | 0;
  return _tmp | (_tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob());
}
function _M0FP37walkzzz13image_2ecodec5codec14box__type__str(data, offset) {
  return _M0FP37walkzzz13image_2ecodec5codec9read__4cc(data, offset + 4 | 0);
}
function _M0FP37walkzzz13image_2ecodec5codec11scan__boxes(data, start, end, callback) {
  let offset = start;
  while (true) {
    if ((offset + 8 | 0) <= end) {
      const box_size = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, offset);
      if (box_size < 8 || box_size > (end - offset | 0)) {
        return;
      }
      const btype = _M0FP37walkzzz13image_2ecodec5codec14box__type__str(data, offset);
      callback(offset, box_size, btype);
      if (btype === "meta" || (btype === "iprp" || (btype === "ipco" || (btype === "moov" || (btype === "trak" || btype === "mdia"))))) {
        const child_start = btype === "meta" ? offset + 12 | 0 : offset + 8 | 0;
        _M0FP37walkzzz13image_2ecodec5codec11scan__boxes(data, child_start, offset + box_size | 0, callback);
      }
      offset = offset + box_size | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec20avif__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec16is__avif__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16AvifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not an AVIF file"));
  }
  const len = data.length;
  const width = new _M0TPB8MutLocalGiE(0);
  const height = new _M0TPB8MutLocalGiE(0);
  const bit_depth = new _M0TPB8MutLocalGiE(8);
  const has_alpha = new _M0TPB8MutLocalGbE(false);
  const rotation = new _M0TPB8MutLocalGiE(0);
  const mirror = new _M0TPB8MutLocalGiE(0);
  const color_type = new _M0TPB8MutLocalGsE("unknown");
  const color_primaries = new _M0TPB8MutLocalGiE(0);
  const transfer_characteristics = new _M0TPB8MutLocalGiE(0);
  const matrix_coefficients = new _M0TPB8MutLocalGiE(0);
  const full_range = new _M0TPB8MutLocalGbE(false);
  const av1_profile = new _M0TPB8MutLocalGiE(0);
  const av1_level = new _M0TPB8MutLocalGiE(0);
  const av1_tier = new _M0TPB8MutLocalGiE(0);
  const av1_monochrome = new _M0TPB8MutLocalGbE(false);
  _M0FP37walkzzz13image_2ecodec5codec11scan__boxes(data, 0, len, (box_off, _box_size, box_type) => {
    if (box_type === "ispe" && (box_off + 20 | 0) <= len) {
      width.val = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, box_off + 12 | 0);
      height.val = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, box_off + 16 | 0);
    }
    if (box_type === "auxC") {
      has_alpha.val = true;
    }
    if (box_type === "pixi" && (box_off + 13 | 0) <= len) {
      const _tmp = box_off + 12 | 0;
      const num_ch = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      if (num_ch > 0 && ((box_off + 13 | 0) + num_ch | 0) <= len) {
        const _tmp$2 = box_off + 13 | 0;
        bit_depth.val = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      }
    }
    if (box_type === "irot" && (box_off + 9 | 0) <= len) {
      const _tmp = box_off + 8 | 0;
      const angle_bits = (_tmp >>> 0 < data.length ? data[_tmp] : $oob()) & 3;
      rotation.val = Math.imul(angle_bits, 90) | 0;
    }
    if (box_type === "imir" && (box_off + 9 | 0) <= len) {
      const _tmp = box_off + 8 | 0;
      mirror.val = (_tmp >>> 0 < data.length ? data[_tmp] : $oob()) & 1;
    }
    if (box_type === "colr" && (box_off + 16 | 0) <= len) {
      const ctype = _M0FP37walkzzz13image_2ecodec5codec9read__4cc(data, box_off + 8 | 0);
      if (ctype === "nclx" && (box_off + 19 | 0) <= len) {
        color_type.val = "nclx";
        color_primaries.val = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, box_off + 12 | 0);
        transfer_characteristics.val = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, box_off + 14 | 0);
        matrix_coefficients.val = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, box_off + 16 | 0);
        const _tmp = box_off + 18 | 0;
        full_range.val = ((_tmp >>> 0 < data.length ? data[_tmp] : $oob()) & 128) !== 0;
      } else {
        if (ctype === "rICC") {
          color_type.val = "rICC";
        } else {
          if (ctype === "prof") {
            color_type.val = "prof";
          }
        }
      }
    }
    if (box_type === "av1C" && (box_off + 12 | 0) <= len) {
      const _tmp = box_off + 9 | 0;
      const b1 = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      av1_profile.val = b1 >> 5 & 7;
      av1_level.val = b1 & 31;
      if ((box_off + 13 | 0) <= len) {
        const _tmp$2 = box_off + 10 | 0;
        const b2 = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
        av1_tier.val = b2 >> 7 & 1;
        av1_monochrome.val = (b2 >> 4 & 1) === 1;
        return;
      } else {
        return;
      }
    } else {
      return;
    }
  });
  if (width.val === 0 || height.val === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16AvifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("AVIF: could not determine image dimensions"));
  }
  const num_channels = has_alpha.val ? 4 : 3;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16AvifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec16AvifInfoExtended(width.val, height.val, bit_depth.val, num_channels, has_alpha.val, rotation.val, mirror.val, color_type.val, color_primaries.val, transfer_characteristics.val, matrix_coefficients.val, full_range.val, av1_profile.val, av1_level.val, av1_tier.val, av1_monochrome.val));
}
function _M0FP37walkzzz13image_2ecodec5codec22bmp__compression__name(c) {
  switch (c) {
    case 0: {
      return "BI_RGB";
    }
    case 1: {
      return "BI_RLE8";
    }
    case 2: {
      return "BI_RLE4";
    }
    case 3: {
      return "BI_BITFIELDS";
    }
    case 4: {
      return "BI_JPEG";
    }
    case 5: {
      return "BI_PNG";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec15is__bmp__format(data) {
  const len = data.length;
  if (len < 14) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 66 && (1 >>> 0 < data.length ? data[1] : $oob()) === 77;
}
function _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, offset) {
  const _tmp = offset >>> 0 < data.length ? data[offset] : $oob();
  const _tmp$2 = offset + 1 | 0;
  return _tmp | (_tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob()) << 8;
}
function _M0FP37walkzzz13image_2ecodec5codec13read__u32__le(data, offset) {
  const _tmp = offset >>> 0 < data.length ? data[offset] : $oob();
  const _tmp$2 = offset + 1 | 0;
  const _tmp$3 = _tmp | (_tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob()) << 8;
  const _tmp$4 = offset + 2 | 0;
  const _tmp$5 = _tmp$3 | (_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob()) << 16;
  const _tmp$6 = offset + 3 | 0;
  return _tmp$5 | (_tmp$6 >>> 0 < data.length ? data[_tmp$6] : $oob()) << 24;
}
function _M0FP37walkzzz13image_2ecodec5codec19bmp__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec15is__bmp__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15BmpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a BMP file"));
  }
  const len = data.length;
  if (len < 54) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15BmpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("BMP 数据过短"));
  }
  const data_offset = _M0FP37walkzzz13image_2ecodec5codec13read__u32__le(data, 10);
  const dib_size = _M0FP37walkzzz13image_2ecodec5codec13read__u32__le(data, 14);
  const width = _M0FP37walkzzz13image_2ecodec5codec13read__u32__le(data, 18);
  const height = _M0FP37walkzzz13image_2ecodec5codec13read__u32__le(data, 22);
  const bpp = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 28);
  const compression = _M0FP37walkzzz13image_2ecodec5codec13read__u32__le(data, 30);
  let num_colors;
  if (dib_size >= 40 && 46 < len) {
    const nc = _M0FP37walkzzz13image_2ecodec5codec13read__u32__le(data, 46);
    num_colors = nc > 0 ? nc : 1 << bpp;
  } else {
    num_colors = 0;
  }
  const abs_width = width < 0 ? -width | 0 : width;
  const abs_height = height < 0 ? -height | 0 : height;
  if (abs_width === 0 || abs_height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15BmpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("BMP 尺寸无效"));
  }
  const is_bottom_up = height > 0;
  const has_alpha = bpp === 32;
  const num_channels = bpp / 8 | 0;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15BmpInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15BmpInfoExtended(abs_width, abs_height, bpp, num_channels, has_alpha, compression, _M0FP37walkzzz13image_2ecodec5codec22bmp__compression__name(compression), is_bottom_up, dib_size, num_colors, data_offset));
}
function _M0FP37walkzzz13image_2ecodec5codec19cur__info__extended(data) {
  const len = data.length;
  if (len < 6) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("CUR 数据过短"));
  }
  const icon_type = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 2);
  const count = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 4);
  if (icon_type !== 2) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a CUR file"));
  }
  if (count === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("CUR 无图像条目"));
  }
  if (len < (6 + (Math.imul(count, 16) | 0) | 0)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("CUR 目录数据不完整"));
  }
  const widths = new _M0TPB5ArrayGiE([], 0);
  const heights = new _M0TPB5ArrayGiE([], 0);
  const hotspot_xs = new _M0TPB5ArrayGiE([], 0);
  const hotspot_ys = new _M0TPB5ArrayGiE([], 0);
  let best_w = 0;
  let best_h = 0;
  let best_area = 0;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < count) {
      const base = 6 + (Math.imul(i, 16) | 0) | 0;
      const w = base >>> 0 < data.length ? data[base] : $oob();
      const _tmp$2 = base + 1 | 0;
      const h = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      const hotspot_x = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, base + 4 | 0);
      const hotspot_y = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, base + 6 | 0);
      const real_w = w === 0 ? 256 : w;
      const real_h = h === 0 ? 256 : h;
      _M0MPC15array5Array4pushGiE(widths, real_w);
      _M0MPC15array5Array4pushGiE(heights, real_h);
      _M0MPC15array5Array4pushGiE(hotspot_xs, hotspot_x);
      _M0MPC15array5Array4pushGiE(hotspot_ys, hotspot_y);
      const area = Math.imul(real_w, real_h) | 0;
      if (area > best_area) {
        best_area = area;
        best_w = real_w;
        best_h = real_h;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15CurInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15CurInfoExtended(icon_type, count, widths, heights, hotspot_xs, hotspot_ys, best_w, best_h, 4, true));
}
function _M0FP37walkzzz13image_2ecodec5codec15is__gif__format(data) {
  const len = data.length;
  if (len < 6) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 71 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 73 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 70 && ((3 >>> 0 < data.length ? data[3] : $oob()) === 56 && ((5 >>> 0 < data.length ? data[5] : $oob()) === 97 && ((4 >>> 0 < data.length ? data[4] : $oob()) === 55 || (4 >>> 0 < data.length ? data[4] : $oob()) === 57)))));
}
function _M0FP37walkzzz13image_2ecodec5codec19gif__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec15is__gif__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15GifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a GIF file"));
  }
  const len = data.length;
  if (len < 13) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15GifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("GIF 数据过短"));
  }
  const version = (4 >>> 0 < data.length ? data[4] : $oob()) === 55 ? "87a" : "89a";
  const width = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 6);
  const height = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 8);
  const packed = 10 >>> 0 < data.length ? data[10] : $oob();
  const has_global_color_table = (packed & 128) !== 0;
  const color_resolution = (packed >> 4 & 7) + 1 | 0;
  const is_sorted = (packed & 8) !== 0;
  const gct_size_bits = packed & 7;
  const global_color_table_size = has_global_color_table ? 1 << (gct_size_bits + 1 | 0) : 0;
  const background_color_index = 11 >>> 0 < data.length ? data[11] : $oob();
  const pixel_aspect_ratio = 12 >>> 0 < data.length ? data[12] : $oob();
  if (width === 0 || height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15GifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("GIF 尺寸无效"));
  }
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15GifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15GifInfoExtended(width, height, version, has_global_color_table, global_color_table_size, color_resolution, is_sorted, background_color_index, pixel_aspect_ratio, 3, false));
}
function _M0FP37walkzzz13image_2ecodec5codec15is__hdr__format(data) {
  const len = data.length;
  if (len < 2) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 35 && (1 >>> 0 < data.length ? data[1] : $oob()) === 63;
}
function _M0FP37walkzzz13image_2ecodec5codec19hdr__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec15is__hdr__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15HdrInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not an HDR file"));
  }
  const len = data.length;
  let pos = 2;
  while (true) {
    let _tmp;
    if (pos < len) {
      const _tmp$2 = pos;
      _tmp = (_tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob()) !== 10;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      pos = pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  pos = pos + 1 | 0;
  let format = "RGBE";
  while (true) {
    if (pos < len) {
      const _tmp = pos;
      const b = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      if (b === 45 || b === 43) {
        break;
      }
      let _tmp$2;
      if ((pos + 7 | 0) <= len) {
        let _tmp$3;
        const _tmp$4 = pos;
        if ((_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob()) === 70) {
          let _tmp$5;
          const _tmp$6 = pos + 1 | 0;
          if ((_tmp$6 >>> 0 < data.length ? data[_tmp$6] : $oob()) === 79) {
            let _tmp$7;
            const _tmp$8 = pos + 2 | 0;
            if ((_tmp$8 >>> 0 < data.length ? data[_tmp$8] : $oob()) === 82) {
              let _tmp$9;
              const _tmp$10 = pos + 3 | 0;
              if ((_tmp$10 >>> 0 < data.length ? data[_tmp$10] : $oob()) === 77) {
                let _tmp$11;
                const _tmp$12 = pos + 4 | 0;
                if ((_tmp$12 >>> 0 < data.length ? data[_tmp$12] : $oob()) === 65) {
                  let _tmp$13;
                  const _tmp$14 = pos + 5 | 0;
                  if ((_tmp$14 >>> 0 < data.length ? data[_tmp$14] : $oob()) === 84) {
                    const _tmp$15 = pos + 6 | 0;
                    _tmp$13 = (_tmp$15 >>> 0 < data.length ? data[_tmp$15] : $oob()) === 61;
                  } else {
                    _tmp$13 = false;
                  }
                  _tmp$11 = _tmp$13;
                } else {
                  _tmp$11 = false;
                }
                _tmp$9 = _tmp$11;
              } else {
                _tmp$9 = false;
              }
              _tmp$7 = _tmp$9;
            } else {
              _tmp$7 = false;
            }
            _tmp$5 = _tmp$7;
          } else {
            _tmp$5 = false;
          }
          _tmp$3 = _tmp$5;
        } else {
          _tmp$3 = false;
        }
        _tmp$2 = _tmp$3;
      } else {
        _tmp$2 = false;
      }
      if (_tmp$2) {
        const fmt_start = pos + 7 | 0;
        let fmt_end = fmt_start;
        while (true) {
          let _tmp$3;
          if (fmt_end < len) {
            const _tmp$4 = fmt_end;
            _tmp$3 = (_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob()) !== 10;
          } else {
            _tmp$3 = false;
          }
          if (_tmp$3) {
            fmt_end = fmt_end + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        const fmt_bytes = new _M0TPB5ArrayGyE(new Uint8Array([]), 0);
        const _bind = fmt_end;
        let _tmp$3 = fmt_start;
        while (true) {
          const i = _tmp$3;
          if (i < _bind) {
            _M0MPC15array5Array4pushGyE(fmt_bytes, i >>> 0 < data.length ? data[i] : $oob());
            _tmp$3 = i + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        let _tmp$4;
        let _try_err;
        _L: {
          _L$2: {
            const _bind$2 = _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(fmt_bytes.buf, 0, fmt_bytes.len));
            const _bind$3 = _M0FPC28encoding4utf814decode_2einner(new _M0TPC15bytes9BytesView(_bind$2, 0, _bind$2.length), false);
            if (_bind$3.$tag === 1) {
              const _ok = _bind$3;
              _tmp$4 = _ok._0;
            } else {
              const _err = _bind$3;
              _try_err = _err._0;
              break _L$2;
            }
            break _L;
          }
          _tmp$4 = "RGBE";
        }
        format = _tmp$4;
      }
      while (true) {
        let _tmp$3;
        if (pos < len) {
          const _tmp$4 = pos;
          _tmp$3 = (_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob()) !== 10;
        } else {
          _tmp$3 = false;
        }
        if (_tmp$3) {
          pos = pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      pos = pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let width = 0;
  let height = 0;
  const vals = new _M0TPB5ArrayGiE([], 0);
  while (true) {
    let _tmp;
    if (pos < len) {
      const _tmp$2 = pos;
      _tmp = (_tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob()) !== 10;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      const _tmp$2 = pos;
      const b = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      if (b === 45 || b === 43) {
        pos = pos + 1 | 0;
        while (true) {
          let _tmp$3;
          if (pos < len) {
            let _tmp$4;
            const _tmp$5 = pos;
            if ((_tmp$5 >>> 0 < data.length ? data[_tmp$5] : $oob()) !== 45) {
              let _tmp$6;
              const _tmp$7 = pos;
              if ((_tmp$7 >>> 0 < data.length ? data[_tmp$7] : $oob()) !== 43) {
                const _tmp$8 = pos;
                _tmp$6 = (_tmp$8 >>> 0 < data.length ? data[_tmp$8] : $oob()) !== 10;
              } else {
                _tmp$6 = false;
              }
              _tmp$4 = _tmp$6;
            } else {
              _tmp$4 = false;
            }
            _tmp$3 = _tmp$4;
          } else {
            _tmp$3 = false;
          }
          if (_tmp$3) {
            const _tmp$4 = pos;
            const c = _tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob();
            if (c >= 48 && c <= 57) {
              let num = 0;
              while (true) {
                if (pos < len) {
                  const _tmp$5 = pos;
                  const d = _tmp$5 >>> 0 < data.length ? data[_tmp$5] : $oob();
                  if (d >= 48 && d <= 57) {
                    num = (Math.imul(num, 10) | 0) + (d - 48 | 0) | 0;
                    pos = pos + 1 | 0;
                  } else {
                    break;
                  }
                  continue;
                } else {
                  break;
                }
              }
              _M0MPC15array5Array4pushGiE(vals, num);
            } else {
              pos = pos + 1 | 0;
            }
            continue;
          } else {
            break;
          }
        }
      } else {
        pos = pos + 1 | 0;
      }
      continue;
    } else {
      break;
    }
  }
  if (vals.len >= 2) {
    if (0 >= vals.len) {
      $panic();
    }
    height = vals.buf[0];
    if (1 >= vals.len) {
      $panic();
    }
    width = vals.buf[1];
  }
  if (width === 0 || height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15HdrInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("HDR 尺寸无效"));
  }
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15HdrInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15HdrInfoExtended(width, height, 3, false, format));
}
function _M0FP37walkzzz13image_2ecodec5codec17heif__scan__boxes(data, start, end, callback) {
  let offset = start;
  while (true) {
    if ((offset + 8 | 0) <= end) {
      const box_size = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, offset);
      if (box_size < 8 || box_size > (end - offset | 0)) {
        return;
      }
      const btype = _M0FP37walkzzz13image_2ecodec5codec14box__type__str(data, offset);
      callback(offset, box_size, btype);
      if (btype === "meta" || (btype === "iprp" || (btype === "ipco" || (btype === "moov" || (btype === "trak" || btype === "mdia"))))) {
        const child_start = btype === "meta" ? offset + 12 | 0 : offset + 8 | 0;
        _M0FP37walkzzz13image_2ecodec5codec17heif__scan__boxes(data, child_start, offset + box_size | 0, callback);
      }
      offset = offset + box_size | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec16is__heif__format(data) {
  const len = data.length;
  if (len < 12) {
    return false;
  }
  if ((4 >>> 0 < data.length ? data[4] : $oob()) !== 102 || ((5 >>> 0 < data.length ? data[5] : $oob()) !== 116 || ((6 >>> 0 < data.length ? data[6] : $oob()) !== 121 || (7 >>> 0 < data.length ? data[7] : $oob()) !== 112))) {
    return false;
  }
  const b8 = 8 >>> 0 < data.length ? data[8] : $oob();
  const b9 = 9 >>> 0 < data.length ? data[9] : $oob();
  const b10 = 10 >>> 0 < data.length ? data[10] : $oob();
  const b11 = 11 >>> 0 < data.length ? data[11] : $oob();
  if (b8 === 104 && (b9 === 101 && (b10 === 105 && b11 === 99))) {
    return true;
  }
  if (b8 === 104 && (b9 === 101 && (b10 === 105 && b11 === 120))) {
    return true;
  }
  if (b8 === 104 && (b9 === 101 && (b10 === 118 && b11 === 99))) {
    return true;
  }
  if (b8 === 109 && (b9 === 105 && (b10 === 102 && b11 === 49))) {
    return true;
  }
  return false;
}
function _M0FP37walkzzz13image_2ecodec5codec20heif__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec16is__heif__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16HeifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a HEIF file"));
  }
  const len = data.length;
  const width = new _M0TPB8MutLocalGiE(0);
  const height = new _M0TPB8MutLocalGiE(0);
  const bit_depth = new _M0TPB8MutLocalGiE(8);
  const has_alpha = new _M0TPB8MutLocalGbE(false);
  const rotation = new _M0TPB8MutLocalGiE(0);
  const mirror = new _M0TPB8MutLocalGiE(0);
  const color_type = new _M0TPB8MutLocalGsE("unknown");
  const color_primaries = new _M0TPB8MutLocalGiE(0);
  const transfer_characteristics = new _M0TPB8MutLocalGiE(0);
  const matrix_coefficients = new _M0TPB8MutLocalGiE(0);
  const full_range = new _M0TPB8MutLocalGbE(false);
  const hevc_profile = new _M0TPB8MutLocalGiE(0);
  const hevc_level = new _M0TPB8MutLocalGiE(0);
  const hevc_tier = new _M0TPB8MutLocalGiE(0);
  const hevc_chroma_format = new _M0TPB8MutLocalGiE(0);
  const hevc_bit_depth_luma = new _M0TPB8MutLocalGiE(8);
  const hevc_bit_depth_chroma = new _M0TPB8MutLocalGiE(8);
  _M0FP37walkzzz13image_2ecodec5codec17heif__scan__boxes(data, 0, len, (box_off, _box_size, box_type) => {
    if (box_type === "ispe" && (box_off + 20 | 0) <= len) {
      width.val = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, box_off + 12 | 0);
      height.val = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, box_off + 16 | 0);
    }
    if (box_type === "auxC") {
      has_alpha.val = true;
    }
    if (box_type === "pixi" && (box_off + 13 | 0) <= len) {
      const _tmp = box_off + 12 | 0;
      const num_ch = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      if (num_ch > 0 && ((box_off + 13 | 0) + num_ch | 0) <= len) {
        const _tmp$2 = box_off + 13 | 0;
        bit_depth.val = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      }
    }
    if (box_type === "irot" && (box_off + 9 | 0) <= len) {
      const _tmp = box_off + 8 | 0;
      const angle_bits = (_tmp >>> 0 < data.length ? data[_tmp] : $oob()) & 3;
      rotation.val = Math.imul(angle_bits, 90) | 0;
    }
    if (box_type === "imir" && (box_off + 9 | 0) <= len) {
      const _tmp = box_off + 8 | 0;
      mirror.val = (_tmp >>> 0 < data.length ? data[_tmp] : $oob()) & 1;
    }
    if (box_type === "colr" && (box_off + 16 | 0) <= len) {
      const ctype = _M0FP37walkzzz13image_2ecodec5codec9read__4cc(data, box_off + 8 | 0);
      if (ctype === "nclx" && (box_off + 19 | 0) <= len) {
        color_type.val = "nclx";
        color_primaries.val = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, box_off + 12 | 0);
        transfer_characteristics.val = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, box_off + 14 | 0);
        matrix_coefficients.val = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, box_off + 16 | 0);
        const _tmp = box_off + 18 | 0;
        full_range.val = ((_tmp >>> 0 < data.length ? data[_tmp] : $oob()) & 128) !== 0;
      } else {
        if (ctype === "rICC") {
          color_type.val = "rICC";
        } else {
          if (ctype === "prof") {
            color_type.val = "prof";
          }
        }
      }
    }
    if (box_type === "hvcC" && (box_off + 22 | 0) <= len) {
      const _tmp = box_off + 9 | 0;
      const b1 = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      hevc_tier.val = b1 >> 6 & 1;
      hevc_profile.val = b1 & 31;
      const _tmp$2 = box_off + 13 | 0;
      hevc_level.val = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      const _tmp$3 = box_off + 21 | 0;
      const chroma_byte = _tmp$3 >>> 0 < data.length ? data[_tmp$3] : $oob();
      hevc_chroma_format.val = chroma_byte & 3;
      if ((box_off + 23 | 0) <= len) {
        const _tmp$4 = box_off + 22 | 0;
        hevc_bit_depth_luma.val = ((_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob()) & 7) + 8 | 0;
      }
      if ((box_off + 24 | 0) <= len) {
        const _tmp$4 = box_off + 23 | 0;
        hevc_bit_depth_chroma.val = ((_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob()) & 7) + 8 | 0;
        return;
      } else {
        return;
      }
    } else {
      return;
    }
  });
  if (width.val === 0 || height.val === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16HeifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("HEIF: could not determine image dimensions"));
  }
  const num_channels = has_alpha.val ? 4 : 3;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16HeifInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec16HeifInfoExtended(width.val, height.val, bit_depth.val, num_channels, has_alpha.val, rotation.val, mirror.val, color_type.val, color_primaries.val, transfer_characteristics.val, matrix_coefficients.val, full_range.val, hevc_profile.val, hevc_level.val, hevc_tier.val, hevc_chroma_format.val, hevc_bit_depth_luma.val, hevc_bit_depth_chroma.val));
}
function _M0FP37walkzzz13image_2ecodec5codec16icns__icon__info(type_code) {
  switch (type_code) {
    case "ic07": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS754;
    }
    case "ic08": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS755;
    }
    case "ic09": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS756;
    }
    case "ic10": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS757;
    }
    case "ic11": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS758;
    }
    case "ic12": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS759;
    }
    case "ic13": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS760;
    }
    case "ic14": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS761;
    }
    case "ic04": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS762;
    }
    case "ic05": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS763;
    }
    case "icp4": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS764;
    }
    case "icp5": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS765;
    }
    case "icp6": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS766;
    }
    case "icp7": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS767;
    }
    case "icp8": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS768;
    }
    case "icp9": {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS769;
    }
    default: {
      return _M0FP37walkzzz13image_2ecodec5codec16icns__icon__infoN5tupleS770;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec22icns__type__to__string(data, offset) {
  const _tmp = offset >>> 0 < data.length ? data[offset] : $oob();
  const _tmp$2 = offset + 1 | 0;
  const _tmp$3 = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
  const _tmp$4 = offset + 2 | 0;
  const _tmp$5 = _tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob();
  const _tmp$6 = offset + 3 | 0;
  let buf_buf = new Uint8Array([_tmp, _tmp$3, _tmp$5, _tmp$6 >>> 0 < data.length ? data[_tmp$6] : $oob()]);
  let buf_len = 4;
  let _try_err;
  _L: {
    const _bind = _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(buf_buf, 0, buf_len));
    const _bind$2 = _M0FPC28encoding4utf814decode_2einner(new _M0TPC15bytes9BytesView(_bind, 0, _bind.length), false);
    if (_bind$2.$tag === 1) {
      const _ok = _bind$2;
      return _ok._0;
    } else {
      const _err = _bind$2;
      _try_err = _err._0;
      break _L;
    }
  }
  return "????";
}
function _M0FP37walkzzz13image_2ecodec5codec16is__icns__format(data) {
  const len = data.length;
  if (len < 8) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 105 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 99 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 110 && (3 >>> 0 < data.length ? data[3] : $oob()) === 115));
}
function _M0FP37walkzzz13image_2ecodec5codec20icns__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec16is__icns__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16IcnsInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not an ICNS file"));
  }
  const len = data.length;
  const file_size = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, 4);
  const icon_types = new _M0TPB5ArrayGsE([], 0);
  const icon_sizes = new _M0TPB5ArrayGiE([], 0);
  const is_png_list = new _M0TPB5ArrayGbE([], 0);
  let pos = 8;
  let max_size = 0;
  while (true) {
    if ((pos + 8 | 0) <= len) {
      const type_code = _M0FP37walkzzz13image_2ecodec5codec22icns__type__to__string(data, pos);
      const chunk_len = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, pos + 4 | 0);
      if (chunk_len < 8 || chunk_len > (len - pos | 0)) {
        break;
      }
      const _bind = _M0FP37walkzzz13image_2ecodec5codec16icns__icon__info(type_code);
      const _icon_size = _bind._0;
      const _is_png = _bind._1;
      if (_icon_size > 0) {
        _M0MPC15array5Array4pushGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(icon_types, type_code);
        _M0MPC15array5Array4pushGiE(icon_sizes, _icon_size);
        _M0MPC15array5Array4pushGbE(is_png_list, _is_png);
        if (_icon_size > max_size) {
          max_size = _icon_size;
        }
      }
      pos = pos + chunk_len | 0;
      continue;
    } else {
      break;
    }
  }
  if (max_size === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16IcnsInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("ICNS 无有效图标"));
  }
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16IcnsInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec16IcnsInfoExtended(file_size, icon_types.len, icon_types, icon_sizes, is_png_list, max_size, max_size, 4, true));
}
function _M0FP37walkzzz13image_2ecodec5codec19ico__info__extended(data) {
  const len = data.length;
  if (len < 6) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("ICO 数据过短"));
  }
  const icon_type = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 2);
  const count = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 4);
  if (icon_type !== 1) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not an ICO file"));
  }
  if (count === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("ICO 无图像条目"));
  }
  if (len < (6 + (Math.imul(count, 16) | 0) | 0)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("ICO 目录数据不完整"));
  }
  const widths = new _M0TPB5ArrayGiE([], 0);
  const heights = new _M0TPB5ArrayGiE([], 0);
  const bit_depths = new _M0TPB5ArrayGiE([], 0);
  let best_w = 0;
  let best_h = 0;
  let best_area = 0;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < count) {
      const base = 6 + (Math.imul(i, 16) | 0) | 0;
      const w = base >>> 0 < data.length ? data[base] : $oob();
      const _tmp$2 = base + 1 | 0;
      const h = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      const planes = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, base + 4 | 0);
      const bit_count = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, base + 6 | 0);
      const real_w = w === 0 ? 256 : w;
      const real_h = h === 0 ? 256 : h;
      const real_bd = planes === 0 ? bit_count : Math.imul(planes, bit_count) | 0;
      _M0MPC15array5Array4pushGiE(widths, real_w);
      _M0MPC15array5Array4pushGiE(heights, real_h);
      _M0MPC15array5Array4pushGiE(bit_depths, real_bd);
      const area = Math.imul(real_w, real_h) | 0;
      if (area > best_area) {
        best_area = area;
        best_w = real_w;
        best_h = real_h;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15IcoInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15IcoInfoExtended(icon_type, "ICO", count, widths, heights, bit_depths, best_w, best_h, 4, true));
}
function _M0FP37walkzzz13image_2ecodec5codec16is__apng__format(data) {
  const len = data.length;
  if (len < 8) {
    return false;
  }
  if (!_M0FP37walkzzz13image_2ecodec5codec18is__png__signature(data, 0)) {
    return false;
  }
  let pos = 8;
  while (true) {
    if ((pos + 8 | 0) <= len) {
      const chunk_len = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, pos);
      const _tmp = pos + 4 | 0;
      const b0 = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      const _tmp$2 = pos + 5 | 0;
      const b1 = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      const _tmp$3 = pos + 6 | 0;
      const b2 = _tmp$3 >>> 0 < data.length ? data[_tmp$3] : $oob();
      const _tmp$4 = pos + 7 | 0;
      const b3 = _tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob();
      if (b0 === 97 && (b1 === 99 && (b2 === 84 && b3 === 76))) {
        return true;
      }
      if (chunk_len < 0 || chunk_len > ((len - pos | 0) - 8 | 0)) {
        break;
      }
      pos = pos + ((8 + chunk_len | 0) + 4 | 0) | 0;
      continue;
    } else {
      break;
    }
  }
  return false;
}
function _M0FP37walkzzz13image_2ecodec5codec15is__cur__format(data) {
  const len = data.length;
  if (len < 6) {
    return false;
  }
  const reserved = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 0);
  const icon_type = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 2);
  const count = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 4);
  return reserved === 0 && (icon_type === 2 && (count >= 1 && len >= (6 + (Math.imul(count, 16) | 0) | 0)));
}
function _M0FP37walkzzz13image_2ecodec5codec15is__ico__format(data) {
  const len = data.length;
  if (len < 6) {
    return false;
  }
  const reserved = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 0);
  const icon_type = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 2);
  const count = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 4);
  return reserved === 0 && (icon_type === 1 && (count >= 1 && len >= (6 + (Math.imul(count, 16) | 0) | 0)));
}
function _M0FP37walkzzz13image_2ecodec5codec16is__jpeg__format(data) {
  const len = data.length;
  if (len < 4) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 255 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 216 && (2 >>> 0 < data.length ? data[2] : $oob()) === 255);
}
function _M0FP37walkzzz13image_2ecodec5codec18is__jpegxl__format(data) {
  const len = data.length;
  if (len < 2) {
    return false;
  }
  if ((0 >>> 0 < data.length ? data[0] : $oob()) === 255 && (1 >>> 0 < data.length ? data[1] : $oob()) === 10) {
    return true;
  }
  if (len >= 12) {
    if ((0 >>> 0 < data.length ? data[0] : $oob()) === 0 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 0 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 0 && ((3 >>> 0 < data.length ? data[3] : $oob()) === 12 && ((4 >>> 0 < data.length ? data[4] : $oob()) === 74 && ((5 >>> 0 < data.length ? data[5] : $oob()) === 88 && ((6 >>> 0 < data.length ? data[6] : $oob()) === 76 && ((7 >>> 0 < data.length ? data[7] : $oob()) === 32 && ((8 >>> 0 < data.length ? data[8] : $oob()) === 13 && ((9 >>> 0 < data.length ? data[9] : $oob()) === 10 && ((10 >>> 0 < data.length ? data[10] : $oob()) === 135 && (11 >>> 0 < data.length ? data[11] : $oob()) === 10))))))))))) {
      return true;
    }
  }
  return false;
}
function _M0FP37walkzzz13image_2ecodec5codec15is__png__format(data) {
  const len = data.length;
  if (len < 8) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 137 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 80 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 78 && ((3 >>> 0 < data.length ? data[3] : $oob()) === 71 && ((4 >>> 0 < data.length ? data[4] : $oob()) === 13 && ((5 >>> 0 < data.length ? data[5] : $oob()) === 10 && ((6 >>> 0 < data.length ? data[6] : $oob()) === 26 && (7 >>> 0 < data.length ? data[7] : $oob()) === 10))))));
}
function _M0FP37walkzzz13image_2ecodec5codec15is__pnm__format(data) {
  const len = data.length;
  if (len < 2) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 80 && ((1 >>> 0 < data.length ? data[1] : $oob()) >= 49 && (1 >>> 0 < data.length ? data[1] : $oob()) <= 54);
}
function _M0FP37walkzzz13image_2ecodec5codec15is__psd__format(data) {
  const len = data.length;
  if (len < 26) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 56 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 66 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 80 && (3 >>> 0 < data.length ? data[3] : $oob()) === 83));
}
function _M0FP37walkzzz13image_2ecodec5codec15is__qoi__format(data) {
  const len = data.length;
  if (len < 14) {
    return false;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 113 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 111 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 105 && (3 >>> 0 < data.length ? data[3] : $oob()) === 102));
}
function _M0FP37walkzzz13image_2ecodec5codec15is__tga__format(data) {
  const len = data.length;
  if (len < 18) {
    return false;
  }
  const color_map_type = 1 >>> 0 < data.length ? data[1] : $oob();
  const image_type = 2 >>> 0 < data.length ? data[2] : $oob();
  const bpp = 16 >>> 0 < data.length ? data[16] : $oob();
  const width = (12 >>> 0 < data.length ? data[12] : $oob()) + (Math.imul(13 >>> 0 < data.length ? data[13] : $oob(), 256) | 0) | 0;
  const height = (14 >>> 0 < data.length ? data[14] : $oob()) + (Math.imul(15 >>> 0 < data.length ? data[15] : $oob(), 256) | 0) | 0;
  if (width === 0 || height === 0) {
    return false;
  }
  if (color_map_type !== 0 && color_map_type !== 1) {
    return false;
  }
  let image_type_ok;
  switch (image_type) {
    case 1: {
      image_type_ok = true;
      break;
    }
    case 2: {
      image_type_ok = true;
      break;
    }
    case 3: {
      image_type_ok = true;
      break;
    }
    case 9: {
      image_type_ok = true;
      break;
    }
    case 10: {
      image_type_ok = true;
      break;
    }
    case 11: {
      image_type_ok = true;
      break;
    }
    default: {
      image_type_ok = false;
    }
  }
  if (!image_type_ok) {
    return false;
  }
  if (color_map_type === 0 && (image_type === 1 || image_type === 9)) {
    return false;
  }
  return bpp === 8 || (bpp === 15 || (bpp === 16 || (bpp === 24 || bpp === 32)));
}
function _M0FP37walkzzz13image_2ecodec5codec16is__tiff__format(data) {
  const len = data.length;
  if (len < 8) {
    return false;
  }
  if ((0 >>> 0 < data.length ? data[0] : $oob()) === 73 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 73 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 42 && (3 >>> 0 < data.length ? data[3] : $oob()) === 0))) {
    return true;
  }
  return (0 >>> 0 < data.length ? data[0] : $oob()) === 77 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 77 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 0 && (3 >>> 0 < data.length ? data[3] : $oob()) === 42));
}
function _M0FP37walkzzz13image_2ecodec5codec21jpeg__is__sof__marker(marker) {
  return marker === 192 || (marker === 193 || (marker === 194 || (marker === 195 || (marker === 197 || (marker === 198 || (marker === 199 || (marker === 201 || (marker === 202 || marker === 203))))))));
}
function _M0FP37walkzzz13image_2ecodec5codec15jpeg__sof__name(marker) {
  switch (marker) {
    case 192: {
      return "Baseline DCT";
    }
    case 193: {
      return "Extended sequential DCT";
    }
    case 194: {
      return "Progressive DCT";
    }
    case 195: {
      return "Lossless sequential";
    }
    case 197: {
      return "Differential sequential DCT";
    }
    case 198: {
      return "Differential progressive DCT";
    }
    case 199: {
      return "Differential lossless";
    }
    case 201: {
      return "Extended sequential arithmetic";
    }
    case 202: {
      return "Progressive arithmetic";
    }
    case 203: {
      return "Lossless arithmetic";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec20jpeg__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec16is__jpeg__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16JpegInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a JPEG file"));
  }
  const len = data.length;
  let pos = 2;
  let width = 0;
  let height = 0;
  let precision = 8;
  let num_components = 3;
  let sof_marker = 192;
  let found_sof = false;
  while (true) {
    if ((pos + 2 | 0) <= len) {
      const _tmp = pos;
      if ((_tmp >>> 0 < data.length ? data[_tmp] : $oob()) !== 255) {
        pos = pos + 1 | 0;
        continue;
      }
      const _tmp$2 = pos + 1 | 0;
      const marker = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
      if (marker === 0 || marker === 255) {
        pos = pos + 1 | 0;
        continue;
      }
      if (marker === 216 || marker === 217) {
        pos = pos + 2 | 0;
        continue;
      }
      if (marker >= 208 && marker <= 215) {
        pos = pos + 2 | 0;
        continue;
      }
      if ((pos + 4 | 0) > len) {
        break;
      }
      const seg_len = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, pos + 2 | 0);
      if (_M0FP37walkzzz13image_2ecodec5codec21jpeg__is__sof__marker(marker) && (pos + 9 | 0) <= len) {
        const _tmp$3 = pos + 4 | 0;
        precision = _tmp$3 >>> 0 < data.length ? data[_tmp$3] : $oob();
        height = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, pos + 5 | 0);
        width = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, pos + 7 | 0);
        const _tmp$4 = pos + 9 | 0;
        num_components = _tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob();
        sof_marker = marker;
        found_sof = true;
        break;
      }
      pos = pos + (2 + seg_len | 0) | 0;
      continue;
    } else {
      break;
    }
  }
  if (!found_sof || (width === 0 || height === 0)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16JpegInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("JPEG: could not determine image dimensions"));
  }
  const is_progressive = sof_marker === 194;
  const is_grayscale = num_components === 1;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16JpegInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec16JpegInfoExtended(width, height, precision, num_components, is_grayscale, is_progressive, sof_marker, _M0FP37walkzzz13image_2ecodec5codec15jpeg__sof__name(sof_marker), num_components, false));
}
function _M0FP37walkzzz13image_2ecodec5codec22is__jpegxl__codestream(data) {
  return data.length >= 2 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 255 && (1 >>> 0 < data.length ? data[1] : $oob()) === 10);
}
function _M0FP37walkzzz13image_2ecodec5codec21jxl__find__codestream(data) {
  const len = data.length;
  let offset = 0;
  while (true) {
    if ((offset + 8 | 0) <= len) {
      const box_size = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, offset);
      if (box_size < 8 || box_size > (len - offset | 0)) {
        break;
      }
      const btype = _M0FP37walkzzz13image_2ecodec5codec14box__type__str(data, offset);
      if (btype === "jxlc" || btype === "jxlp") {
        return offset + 8 | 0;
      }
      offset = offset + box_size | 0;
      continue;
    } else {
      break;
    }
  }
  return -1;
}
function _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader9read__bit(self) {
  if (self.byte_pos >= self.data.length) {
    return 0;
  }
  const _tmp = self.data;
  const _tmp$2 = self.byte_pos;
  const byte = _tmp$2 >>> 0 < _tmp.length ? _tmp[_tmp$2] : $oob();
  const bit = byte >> (7 - self.bit_pos | 0) & 1;
  self.bit_pos = self.bit_pos + 1 | 0;
  if (self.bit_pos === 8) {
    self.bit_pos = 0;
    self.byte_pos = self.byte_pos + 1 | 0;
  }
  return bit;
}
function _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader10read__bits(self, n) {
  let result = 0;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < n) {
      result = result << 1 | _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader9read__bit(self);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader9read__u32(self, d0, d1, d2, d3) {
  const selector = _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader10read__bits(self, 2);
  switch (selector) {
    case 0: {
      return d0;
    }
    case 1: {
      return d1 + _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader10read__bits(self, 8) | 0;
    }
    case 2: {
      return d2 + _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader10read__bits(self, 16) | 0;
    }
    default: {
      return d3 + _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader10read__bits(self, 24) | 0;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec23jxl__width__from__ratio(height, ratio, reader) {
  switch (ratio) {
    case 0: {
      return height;
    }
    case 1: {
      return (Math.imul(height, 4) | 0) / 3 | 0;
    }
    case 2: {
      return (Math.imul(height, 3) | 0) / 2 | 0;
    }
    case 3: {
      return (Math.imul(height, 16) | 0) / 9 | 0;
    }
    case 4: {
      return (Math.imul(height, 5) | 0) / 4 | 0;
    }
    case 5: {
      return Math.imul(height, 2) | 0;
    }
    case 6: {
      return height >= 2 ? height / 2 | 0 : 1;
    }
    default: {
      return _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader9read__u32(reader, 1, 257, 65793, 0) + 1 | 0;
    }
  }
}
function _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader3new(data, start) {
  return new _M0TP37walkzzz13image_2ecodec5codec12JxlBitReader(data, start, 0);
}
function _M0FP37walkzzz13image_2ecodec5codec24jxl__parse__size__header(data, start) {
  const reader = _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader3new(data, start);
  const small = _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader9read__bit(reader);
  const height = small === 1 ? _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader10read__bits(reader, 5) + 1 | 0 : _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader9read__u32(reader, 1, 257, 65793, 0) + 1 | 0;
  const ratio = _M0MP37walkzzz13image_2ecodec5codec12JxlBitReader10read__bits(reader, 3);
  const width = _M0FP37walkzzz13image_2ecodec5codec23jxl__width__from__ratio(height, ratio, reader);
  return { _0: width, _1: height };
}
function _M0FP37walkzzz13image_2ecodec5codec22jpegxl__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec18is__jpegxl__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec18JpegXlInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a JPEG-XL file"));
  }
  const is_cs = _M0FP37walkzzz13image_2ecodec5codec22is__jpegxl__codestream(data);
  let codestream_start;
  if (is_cs) {
    codestream_start = 2;
  } else {
    const cs = _M0FP37walkzzz13image_2ecodec5codec21jxl__find__codestream(data);
    if (cs < 0) {
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec18JpegXlInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("JPEG-XL: codestream box not found in container"));
    }
    codestream_start = cs;
  }
  const _bind = _M0FP37walkzzz13image_2ecodec5codec24jxl__parse__size__header(data, codestream_start);
  const _width = _bind._0;
  const _height = _bind._1;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec18JpegXlInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec18JpegXlInfoExtended(_width, _height, 8, 3, false, false, is_cs, 1));
}
function _M0FP37walkzzz13image_2ecodec5codec20png__channels__count(ct) {
  switch (ct) {
    case 0: {
      return 1;
    }
    case 2: {
      return 3;
    }
    case 3: {
      return 1;
    }
    case 4: {
      return 2;
    }
    case 6: {
      return 4;
    }
    default: {
      return 0;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec22png__color__type__name(ct) {
  switch (ct) {
    case 0: {
      return "Grayscale";
    }
    case 2: {
      return "RGB";
    }
    case 3: {
      return "Palette";
    }
    case 4: {
      return "Grayscale+Alpha";
    }
    case 6: {
      return "RGBA";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec19png__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec15is__png__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a PNG file"));
  }
  const len = data.length;
  if (len < 29) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("PNG 数据过短，无法读取 IHDR"));
  }
  if ((12 >>> 0 < data.length ? data[12] : $oob()) !== 73 || ((13 >>> 0 < data.length ? data[13] : $oob()) !== 72 || ((14 >>> 0 < data.length ? data[14] : $oob()) !== 68 || (15 >>> 0 < data.length ? data[15] : $oob()) !== 82))) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("PNG IHDR chunk 不存在"));
  }
  const width = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, 16);
  const height = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, 20);
  const bit_depth = 24 >>> 0 < data.length ? data[24] : $oob();
  const color_type = 25 >>> 0 < data.length ? data[25] : $oob();
  const compression_method = 26 >>> 0 < data.length ? data[26] : $oob();
  const filter_method = 27 >>> 0 < data.length ? data[27] : $oob();
  const interlace_method = 28 >>> 0 < data.length ? data[28] : $oob();
  if (width === 0 || height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("PNG 尺寸无效"));
  }
  const num_channels = _M0FP37walkzzz13image_2ecodec5codec20png__channels__count(color_type);
  const has_alpha = color_type === 4 || color_type === 6;
  const is_palette = color_type === 3;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PngInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15PngInfoExtended(width, height, bit_depth, color_type, _M0FP37walkzzz13image_2ecodec5codec22png__color__type__name(color_type), num_channels, has_alpha, is_palette, compression_method, filter_method, interlace_method));
}
function _M0FP37walkzzz13image_2ecodec5codec21pnm__read__ascii__int(data, pos, len) {
  const start = pos.val;
  while (true) {
    if (pos.val < len) {
      const _tmp = pos.val;
      const b = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      if (b >= 48 && b <= 57) {
        pos.val = pos.val + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  if (pos.val === start) {
    return new _M0DTPC16result6ResultGiRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("PNM header 数字解析失败"));
  }
  let result = 0;
  const _bind = pos.val;
  let _tmp = start;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      result = (Math.imul(result, 10) | 0) + ((i >>> 0 < data.length ? data[i] : $oob()) - 48 | 0) | 0;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0DTPC16result6ResultGiRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(result);
}
function _M0FP37walkzzz13image_2ecodec5codec19pnm__is__whitespace(b) {
  return b === 32 || (b === 9 || (b === 10 || b === 13));
}
function _M0FP37walkzzz13image_2ecodec5codec28pnm__skip__ws__and__comments(data, pos, len) {
  while (true) {
    if (pos.val < len) {
      const _tmp = pos.val;
      const b = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
      if (_M0FP37walkzzz13image_2ecodec5codec19pnm__is__whitespace(b)) {
        pos.val = pos.val + 1 | 0;
      } else {
        if (b === 35) {
          while (true) {
            let _tmp$2;
            if (pos.val < len) {
              const _tmp$3 = pos.val;
              _tmp$2 = (_tmp$3 >>> 0 < data.length ? data[_tmp$3] : $oob()) !== 10;
            } else {
              _tmp$2 = false;
            }
            if (_tmp$2) {
              pos.val = pos.val + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          if (pos.val < len) {
            pos.val = pos.val + 1 | 0;
          }
        } else {
          return;
        }
      }
      continue;
    } else {
      return;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec19pnm__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec15is__pnm__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PnmInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a PNM file"));
  }
  const len = data.length;
  const magic1 = 1 >>> 0 < data.length ? data[1] : $oob();
  const format_type = `P${_M0MPC13int3Int18to__string_2einner(magic1 - 48 | 0, 10)}`;
  const is_binary = magic1 >= 52;
  let num_channels;
  switch (magic1) {
    case 49: {
      num_channels = 1;
      break;
    }
    case 52: {
      num_channels = 1;
      break;
    }
    case 50: {
      num_channels = 1;
      break;
    }
    case 53: {
      num_channels = 1;
      break;
    }
    case 51: {
      num_channels = 3;
      break;
    }
    case 54: {
      num_channels = 3;
      break;
    }
    default: {
      num_channels = 0;
    }
  }
  const pos = _M0MPC13ref3Ref3RefGiE(2);
  _M0FP37walkzzz13image_2ecodec5codec28pnm__skip__ws__and__comments(data, pos, len);
  const _bind = _M0FP37walkzzz13image_2ecodec5codec21pnm__read__ascii__int(data, pos, len);
  let width;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    width = _ok._0;
  } else {
    return _bind;
  }
  _M0FP37walkzzz13image_2ecodec5codec28pnm__skip__ws__and__comments(data, pos, len);
  const _bind$2 = _M0FP37walkzzz13image_2ecodec5codec21pnm__read__ascii__int(data, pos, len);
  let height;
  if (_bind$2.$tag === 1) {
    const _ok = _bind$2;
    height = _ok._0;
  } else {
    return _bind$2;
  }
  let maxval;
  if (magic1 === 49 || magic1 === 52) {
    maxval = 1;
  } else {
    _M0FP37walkzzz13image_2ecodec5codec28pnm__skip__ws__and__comments(data, pos, len);
    const _bind$3 = _M0FP37walkzzz13image_2ecodec5codec21pnm__read__ascii__int(data, pos, len);
    if (_bind$3.$tag === 1) {
      const _ok = _bind$3;
      maxval = _ok._0;
    } else {
      return _bind$3;
    }
  }
  if (width === 0 || height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PnmInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("PNM 尺寸无效"));
  }
  const bit_depth = maxval < 256 ? 8 : 16;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PnmInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15PnmInfoExtended(width, height, format_type, maxval, bit_depth, num_channels, false, is_binary));
}
function _M0FP37walkzzz13image_2ecodec5codec22psd__color__mode__name(m) {
  switch (m) {
    case 0: {
      return "Bitmap";
    }
    case 1: {
      return "Grayscale";
    }
    case 2: {
      return "Indexed";
    }
    case 3: {
      return "RGB";
    }
    case 4: {
      return "CMYK";
    }
    case 7: {
      return "Multichannel";
    }
    case 8: {
      return "Duotone";
    }
    case 9: {
      return "Lab";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec22psd__compression__name(c) {
  switch (c) {
    case 0: {
      return "Raw";
    }
    case 1: {
      return "RLE";
    }
    case 2: {
      return "ZIP without prediction";
    }
    case 3: {
      return "ZIP with prediction";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec19psd__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec15is__psd__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PsdInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a PSD file"));
  }
  const len = data.length;
  const version = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, 4);
  const channel_count = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, 12);
  const height = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, 14);
  const width = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, 18);
  const bit_depth = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, 22);
  const color_mode = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, 24);
  if (width === 0 || height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PsdInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("PSD 尺寸无效"));
  }
  let pos = 26;
  let compression = 0;
  let _tmp = 0;
  while (true) {
    const seg_idx = _tmp;
    if (seg_idx < 3) {
      if ((pos + 4 | 0) > len) {
        break;
      }
      const seg_len = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, pos);
      pos = pos + 4 | 0;
      if (seg_len > (len - pos | 0)) {
        break;
      }
      pos = pos + seg_len | 0;
      _tmp = seg_idx + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if ((pos + 2 | 0) <= len) {
    compression = _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(data, pos);
  }
  const has_alpha = channel_count === 4 || channel_count === 5;
  const num_channels = channel_count > 4 ? 4 : channel_count;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15PsdInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15PsdInfoExtended(width, height, bit_depth, channel_count, num_channels, has_alpha, color_mode, _M0FP37walkzzz13image_2ecodec5codec22psd__color__mode__name(color_mode), compression, _M0FP37walkzzz13image_2ecodec5codec22psd__compression__name(compression), version));
}
function _M0FP37walkzzz13image_2ecodec5codec19qoi__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec15is__qoi__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15QoiInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a QOI file"));
  }
  const width = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, 4);
  const height = _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(data, 8);
  const channels = 12 >>> 0 < data.length ? data[12] : $oob();
  const colorspace = 13 >>> 0 < data.length ? data[13] : $oob();
  if (width === 0 || height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15QoiInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("QOI 尺寸无效"));
  }
  if (channels !== 3 && channels !== 4) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15QoiInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("QOI 通道数无效"));
  }
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15QoiInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15QoiInfoExtended(width, height, channels, colorspace, colorspace === 0 ? "sRGB with linear alpha" : "all linear", channels, channels === 4));
}
function _M0FP37walkzzz13image_2ecodec5codec22tga__image__type__name(t) {
  switch (t) {
    case 0: {
      return "no image data";
    }
    case 1: {
      return "uncompressed color-mapped";
    }
    case 2: {
      return "uncompressed true-color";
    }
    case 3: {
      return "uncompressed grayscale";
    }
    case 9: {
      return "RLE color-mapped";
    }
    case 10: {
      return "RLE true-color";
    }
    case 11: {
      return "RLE grayscale";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec19tga__info__extended(data) {
  const len = data.length;
  if (len < 18) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TGA 数据过短"));
  }
  const id_length = 0 >>> 0 < data.length ? data[0] : $oob();
  const color_map_type = 1 >>> 0 < data.length ? data[1] : $oob();
  const image_type = 2 >>> 0 < data.length ? data[2] : $oob();
  const x_origin = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 8);
  const y_origin = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 10);
  const width = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 12);
  const height = _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(data, 14);
  const bpp = 16 >>> 0 < data.length ? data[16] : $oob();
  const descriptor = 17 >>> 0 < data.length ? data[17] : $oob();
  if (color_map_type !== 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TGA 颜色映射类型不支持"));
  }
  if (image_type !== 2 && (image_type !== 10 && (image_type !== 3 && image_type !== 11))) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TGA image type 不支持"));
  }
  if (bpp !== 8 && (bpp !== 24 && bpp !== 32)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TGA 位深不支持"));
  }
  if (width === 0 || height === 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TGA 尺寸无效"));
  }
  const is_bottom_up = (descriptor & 32) === 0;
  const num_channels = bpp / 8 | 0;
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec15TgaInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec15TgaInfoExtended(width, height, image_type, _M0FP37walkzzz13image_2ecodec5codec22tga__image__type__name(image_type), bpp, num_channels, bpp === 32, is_bottom_up, id_length, color_map_type, x_origin, y_origin));
}
function _M0FP37walkzzz13image_2ecodec5codec23tiff__compression__name(c) {
  switch (c) {
    case 1: {
      return "none";
    }
    case 2: {
      return "CCITT RLE";
    }
    case 5: {
      return "LZW";
    }
    case 6: {
      return "JPEG";
    }
    case 7: {
      return "JPEG lossy";
    }
    case 8: {
      return "Deflate";
    }
    case 32773: {
      return "PackBits";
    }
    case 32946: {
      return "Deflate (old)";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u16(ctx, offset) {
  return ctx.little_endian ? _M0FP37walkzzz13image_2ecodec5codec13read__u16__le(ctx.data, offset) : _M0FP37walkzzz13image_2ecodec5codec13read__u16__be(ctx.data, offset);
}
function _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u32(ctx, offset) {
  return ctx.little_endian ? _M0FP37walkzzz13image_2ecodec5codec13read__u32__le(ctx.data, offset) : _M0FP37walkzzz13image_2ecodec5codec13read__u32__be(ctx.data, offset);
}
function _M0FP37walkzzz13image_2ecodec5codec16tiff__type__size(type_id) {
  switch (type_id) {
    case 1: {
      return 1;
    }
    case 2: {
      return 1;
    }
    case 3: {
      return 2;
    }
    case 4: {
      return 4;
    }
    case 5: {
      return 8;
    }
    case 6: {
      return 1;
    }
    case 7: {
      return 1;
    }
    case 8: {
      return 2;
    }
    case 9: {
      return 4;
    }
    case 10: {
      return 8;
    }
    case 11: {
      return 4;
    }
    case 12: {
      return 8;
    }
    default: {
      return 0;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec18tiff__read__values(ctx, entry) {
  const total_bytes = Math.imul(_M0FP37walkzzz13image_2ecodec5codec16tiff__type__size(entry.type_id), entry.count) | 0;
  const values = new _M0TPB5ArrayGiE([], 0);
  if (total_bytes <= 4) {
    const v = entry.value_or_offset;
    _L: {
      _L$2: {
        const _bind = entry.type_id;
        switch (_bind) {
          case 1: {
            break _L$2;
          }
          case 7: {
            break _L$2;
          }
          case 3: {
            const _bind$2 = entry.count;
            let _tmp = 0;
            while (true) {
              const i = _tmp;
              if (i < _bind$2) {
                _M0MPC15array5Array4pushGiE(values, v >> (Math.imul(i, 16) | 0) & 65535);
                _tmp = i + 1 | 0;
                continue;
              } else {
                break;
              }
            }
            break;
          }
          case 4: {
            _M0MPC15array5Array4pushGiE(values, v);
            break;
          }
          default: {
            const _bind$3 = entry.count;
            let _tmp$2 = 0;
            while (true) {
              const _ = _tmp$2;
              if (_ < _bind$3) {
                _M0MPC15array5Array4pushGiE(values, 0);
                _tmp$2 = _ + 1 | 0;
                continue;
              } else {
                break;
              }
            }
          }
        }
        break _L;
      }
      const _bind = entry.count;
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < _bind) {
          _M0MPC15array5Array4pushGiE(values, v >> (Math.imul(i, 8) | 0) & 255);
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
  } else {
    const base = entry.value_or_offset;
    const len = ctx.data.length;
    _L: {
      _L$2: {
        const _bind = entry.type_id;
        switch (_bind) {
          case 1: {
            break _L$2;
          }
          case 7: {
            break _L$2;
          }
          case 3: {
            const _bind$2 = entry.count;
            let _tmp = 0;
            while (true) {
              const i = _tmp;
              if (i < _bind$2) {
                _M0MPC15array5Array4pushGiE(values, _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u16(ctx, base + (Math.imul(i, 2) | 0) | 0));
                _tmp = i + 1 | 0;
                continue;
              } else {
                break;
              }
            }
            break;
          }
          case 4: {
            const _bind$3 = entry.count;
            let _tmp$2 = 0;
            while (true) {
              const i = _tmp$2;
              if (i < _bind$3) {
                _M0MPC15array5Array4pushGiE(values, _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u32(ctx, base + (Math.imul(i, 4) | 0) | 0));
                _tmp$2 = i + 1 | 0;
                continue;
              } else {
                break;
              }
            }
            break;
          }
          default: {
            const _bind$4 = entry.count;
            let _tmp$3 = 0;
            while (true) {
              const _ = _tmp$3;
              if (_ < _bind$4) {
                _M0MPC15array5Array4pushGiE(values, 0);
                _tmp$3 = _ + 1 | 0;
                continue;
              } else {
                break;
              }
            }
          }
        }
        break _L;
      }
      const _bind = entry.count;
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < _bind) {
          if ((base + i | 0) < len) {
            const _tmp$2 = ctx.data;
            const _tmp$3 = base + i | 0;
            _M0MPC15array5Array4pushGiE(values, _tmp$3 >>> 0 < _tmp$2.length ? _tmp$2[_tmp$3] : $oob());
          } else {
            _M0MPC15array5Array4pushGiE(values, 0);
          }
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
  }
  return values;
}
function _M0FP37walkzzz13image_2ecodec5codec17tiff__get__values(entries, ctx, tag) {
  const _bind = entries.len;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      if (i < 0 || i >= entries.len) {
        $panic();
      }
      if (entries.buf[i].tag === tag) {
        if (i < 0 || i >= entries.len) {
          $panic();
        }
        return _M0FP37walkzzz13image_2ecodec5codec18tiff__read__values(ctx, entries.buf[i]);
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return undefined;
}
function _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, tag) {
  const _bind = _M0FP37walkzzz13image_2ecodec5codec17tiff__get__values(entries, ctx, tag);
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _arr = _Some;
    if (_arr.len > 0) {
      if (0 >= _arr.len) {
        $panic();
      }
      return _arr.buf[0];
    } else {
      return undefined;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec16tiff__parse__ifd(ctx, ifd_offset) {
  const len = ctx.data.length;
  if ((ifd_offset + 2 | 0) > len) {
    return new _M0DTPC16result6ResultGRPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryERP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TIFF IFD 偏移越界"));
  }
  const count = _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u16(ctx, ifd_offset);
  if (((ifd_offset + 2 | 0) + (Math.imul(count, 12) | 0) | 0) > len) {
    return new _M0DTPC16result6ResultGRPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryERP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TIFF IFD 条目数据不完整"));
  }
  const entries = new _M0TPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE([], 0);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < count) {
      const base = (ifd_offset + 2 | 0) + (Math.imul(i, 12) | 0) | 0;
      const tag = _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u16(ctx, base);
      const type_id = _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u16(ctx, base + 2 | 0);
      const cnt = _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u32(ctx, base + 4 | 0);
      const val_or_off = _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u32(ctx, base + 8 | 0);
      _M0MPC15array5Array4pushGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryE(entries, new _M0TP37walkzzz13image_2ecodec5codec12TiffIfdEntry(tag, type_id, cnt, val_or_off));
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0DTPC16result6ResultGRPB5ArrayGRP37walkzzz13image_2ecodec5codec12TiffIfdEntryERP37walkzzz12image_2ecore5types9LoadErrorE2Ok(entries);
}
function _M0FP37walkzzz13image_2ecodec5codec23tiff__photometric__name(p) {
  switch (p) {
    case 0: {
      return "WhiteIsZero";
    }
    case 1: {
      return "BlackIsZero";
    }
    case 2: {
      return "RGB";
    }
    case 3: {
      return "Palette";
    }
    case 4: {
      return "TransparencyMask";
    }
    case 5: {
      return "CMYK";
    }
    case 6: {
      return "YCbCr";
    }
    case 8: {
      return "CIELab";
    }
    default: {
      return "unknown";
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec20tiff__info__extended(data) {
  if (!_M0FP37walkzzz13image_2ecodec5codec16is__tiff__format(data)) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Not a TIFF file"));
  }
  const len = data.length;
  const little_endian = (0 >>> 0 < data.length ? data[0] : $oob()) === 73;
  const ctx = new _M0TP37walkzzz13image_2ecodec5codec11TiffContext(data, little_endian);
  const ifd_offset = _M0FP37walkzzz13image_2ecodec5codec15tiff__read__u32(ctx, 4);
  if (ifd_offset < 0 || ifd_offset >= len) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TIFF IFD 偏移无效"));
  }
  const _bind = _M0FP37walkzzz13image_2ecodec5codec16tiff__parse__ifd(ctx, ifd_offset);
  let entries;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    entries = _ok._0;
  } else {
    return _bind;
  }
  const _bind$2 = _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, 256);
  let width;
  if (_bind$2 === undefined) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TIFF 缺少 ImageWidth"));
  } else {
    const _Some = _bind$2;
    width = _Some;
  }
  const _bind$3 = _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, 257);
  let height;
  if (_bind$3 === undefined) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TIFF 缺少 ImageLength"));
  } else {
    const _Some = _bind$3;
    height = _Some;
  }
  const _bind$4 = _M0FP37walkzzz13image_2ecodec5codec17tiff__get__values(entries, ctx, 258);
  let bits_per_sample;
  if (_bind$4 === undefined) {
    bits_per_sample = 8;
  } else {
    const _Some = _bind$4;
    const _arr = _Some;
    if (_arr.len > 0) {
      if (0 >= _arr.len) {
        $panic();
      }
      bits_per_sample = _arr.buf[0];
    } else {
      bits_per_sample = 8;
    }
  }
  const _bind$5 = _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, 259);
  let compression;
  if (_bind$5 === undefined) {
    compression = 1;
  } else {
    const _Some = _bind$5;
    compression = _Some;
  }
  const _bind$6 = _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, 262);
  let photometric;
  if (_bind$6 === undefined) {
    photometric = 1;
  } else {
    const _Some = _bind$6;
    photometric = _Some;
  }
  const _bind$7 = _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, 277);
  let samples_per_pixel;
  if (_bind$7 === undefined) {
    samples_per_pixel = 1;
  } else {
    const _Some = _bind$7;
    samples_per_pixel = _Some;
  }
  const _bind$8 = _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, 274);
  let orientation;
  if (_bind$8 === undefined) {
    orientation = 1;
  } else {
    const _Some = _bind$8;
    orientation = _Some;
  }
  const _bind$9 = _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, 296);
  let resolution_unit;
  if (_bind$9 === undefined) {
    resolution_unit = 2;
  } else {
    const _Some = _bind$9;
    resolution_unit = _Some;
  }
  const _bind$10 = _M0FP37walkzzz13image_2ecodec5codec16tiff__get__value(entries, ctx, 338);
  let extra_samples;
  if (_bind$10 === undefined) {
    extra_samples = 0;
  } else {
    const _Some = _bind$10;
    extra_samples = _Some;
  }
  if (width <= 0 || height <= 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("TIFF 尺寸无效"));
  }
  const has_alpha = extra_samples > 0 || (samples_per_pixel === 4 || samples_per_pixel === 2 && photometric === 1);
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec16TiffInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec5codec16TiffInfoExtended(width, height, bits_per_sample, samples_per_pixel, samples_per_pixel, has_alpha, compression, _M0FP37walkzzz13image_2ecodec5codec23tiff__compression__name(compression), photometric, _M0FP37walkzzz13image_2ecodec5codec23tiff__photometric__name(photometric), orientation, resolution_unit, little_endian));
}
function _M0FP37walkzzz13image_2ecodec5codec26get__image__info__extended(data) {
  if (_M0FP37walkzzz13image_2ecodec5codec16is__apng__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec20apng__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Apng(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__png__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19png__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Png(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec16is__jpeg__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec20jpeg__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Jpeg(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__bmp__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19bmp__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Bmp(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__gif__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19gif__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Gif(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__qoi__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19qoi__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Qoi(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__hdr__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19hdr__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Hdr(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__pnm__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19pnm__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Pnm(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec16is__icns__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec20icns__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Icns(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec16is__webp__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec20webp__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Webp(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec16is__tiff__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec20tiff__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Tiff(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__psd__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19psd__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Psd(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec16is__avif__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec20avif__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Avif(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec16is__heif__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec20heif__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended4Heif(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec18is__jpegxl__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec22jpegxl__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended6JpegXl(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__ico__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19ico__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Ico(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__cur__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19cur__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Cur(_tmp));
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__tga__format(data)) {
    const _bind = _M0FP37walkzzz13image_2ecodec5codec19tga__info__extended(data);
    let _tmp;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0DTP37walkzzz13image_2ecodec5codec17ImageInfoExtended3Tga(_tmp));
  }
  return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec5codec17ImageInfoExtendedRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error62walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eUnsupportedFormat("Unknown image format"));
}
function _M0FP37walkzzz13image_2ecodec5codec16png__filter__row(raw, prev, bpp, ft) {
  const n = raw.len;
  const out = _M0MPC15array5Array4makeGyE(n, 0);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < n) {
      if (i < 0 || i >= raw.len) {
        $panic();
      }
      const cur = raw.buf[i];
      let left;
      if (i >= bpp) {
        const _bind = i - bpp | 0;
        if (_bind < 0 || _bind >= raw.len) {
          $panic();
        }
        left = raw.buf[_bind];
      } else {
        left = 0;
      }
      if (i < 0 || i >= prev.len) {
        $panic();
      }
      const up = prev.buf[i];
      let ul;
      if (i >= bpp) {
        const _bind = i - bpp | 0;
        if (_bind < 0 || _bind >= prev.len) {
          $panic();
        }
        ul = prev.buf[_bind];
      } else {
        ul = 0;
      }
      let pred;
      switch (ft) {
        case 1: {
          pred = left;
          break;
        }
        case 2: {
          pred = up;
          break;
        }
        case 3: {
          pred = (left + up | 0) / 2 | 0;
          break;
        }
        case 4: {
          const p = (left + up | 0) - ul | 0;
          const pa = p > left ? p - left | 0 : left - p | 0;
          const pb = p > up ? p - up | 0 : up - p | 0;
          const pc = p > ul ? p - ul | 0 : ul - p | 0;
          pred = pa <= pb && pa <= pc ? left : pb <= pc ? up : ul;
          break;
        }
        default: {
          pred = 0;
        }
      }
      const _bind = cur - pred & 255;
      if (i < 0 || i >= out.len) {
        $panic();
      }
      out.buf[i] = _bind;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return out;
}
function _M0FP37walkzzz13image_2ecodec5codec18png__filter__score(row) {
  let s = 0;
  const _bind = row.len;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      if (i < 0 || i >= row.len) {
        $panic();
      }
      const v = row.buf[i];
      s = s + (v < 128 ? v : 256 - v | 0) | 0;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return s;
}
function _M0FP37walkzzz13image_2ecodec5codec12write__chunk(out, chunk_type, data) {
  const len = data.length;
  _M0MPC15array5Array4pushGyE(out, len >> 24 & 255);
  _M0MPC15array5Array4pushGyE(out, len >> 16 & 255);
  _M0MPC15array5Array4pushGyE(out, len >> 8 & 255);
  _M0MPC15array5Array4pushGyE(out, len & 255);
  const type_bytes = _M0FPC28encoding4utf814encode_2einner(new _M0TPC16string10StringView(chunk_type, 0, chunk_type.length), false);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < 4) {
      _M0MPC15array5Array4pushGyE(out, i >>> 0 < type_bytes.length ? type_bytes[i] : $oob());
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let _tmp$2 = 0;
  while (true) {
    const i = _tmp$2;
    if (i < len) {
      _M0MPC15array5Array4pushGyE(out, i >>> 0 < data.length ? data[i] : $oob());
      _tmp$2 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const crc_data = new _M0TPB5ArrayGyE(new Uint8Array([]), 0);
  let _tmp$3 = 0;
  while (true) {
    const i = _tmp$3;
    if (i < 4) {
      _M0MPC15array5Array4pushGyE(crc_data, i >>> 0 < type_bytes.length ? type_bytes[i] : $oob());
      _tmp$3 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let _tmp$4 = 0;
  while (true) {
    const i = _tmp$4;
    if (i < len) {
      _M0MPC15array5Array4pushGyE(crc_data, i >>> 0 < data.length ? data[i] : $oob());
      _tmp$4 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const crc = _M0FP37walkzzz13image_2ecodec4util5crc32(_M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(crc_data.buf, 0, crc_data.len)));
  _M0MPC15array5Array4pushGyE(out, crc >> 24 & 255);
  _M0MPC15array5Array4pushGyE(out, crc >> 16 & 255);
  _M0MPC15array5Array4pushGyE(out, crc >> 8 & 255);
  _M0MPC15array5Array4pushGyE(out, crc & 255);
}
function _M0FP37walkzzz13image_2ecodec5codec10dist__base(i) {
  switch (i) {
    case 0: {
      return 1;
    }
    case 1: {
      return 2;
    }
    case 2: {
      return 3;
    }
    case 3: {
      return 4;
    }
    case 4: {
      return 5;
    }
    case 5: {
      return 7;
    }
    case 6: {
      return 9;
    }
    case 7: {
      return 13;
    }
    case 8: {
      return 17;
    }
    case 9: {
      return 25;
    }
    case 10: {
      return 33;
    }
    case 11: {
      return 49;
    }
    case 12: {
      return 65;
    }
    case 13: {
      return 97;
    }
    case 14: {
      return 129;
    }
    case 15: {
      return 193;
    }
    case 16: {
      return 257;
    }
    case 17: {
      return 385;
    }
    case 18: {
      return 513;
    }
    case 19: {
      return 769;
    }
    case 20: {
      return 1025;
    }
    case 21: {
      return 1537;
    }
    case 22: {
      return 2049;
    }
    case 23: {
      return 3073;
    }
    case 24: {
      return 4097;
    }
    case 25: {
      return 6145;
    }
    case 26: {
      return 8193;
    }
    case 27: {
      return 12289;
    }
    case 28: {
      return 16385;
    }
    default: {
      return 24577;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec5hash3(data, pos) {
  const a = pos >>> 0 < data.length ? data[pos] : $oob();
  const _tmp = pos + 1 | 0;
  const b = _tmp >>> 0 < data.length ? data[_tmp] : $oob();
  const _tmp$2 = pos + 2 | 0;
  const c = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
  return ((Math.imul(a, 40503) | 0) + (Math.imul(b, 433) | 0) | 0) + c & 32767;
}
function _M0FP37walkzzz13image_2ecodec5codec9len__base(i) {
  switch (i) {
    case 0: {
      return 3;
    }
    case 1: {
      return 4;
    }
    case 2: {
      return 5;
    }
    case 3: {
      return 6;
    }
    case 4: {
      return 7;
    }
    case 5: {
      return 8;
    }
    case 6: {
      return 9;
    }
    case 7: {
      return 10;
    }
    case 8: {
      return 11;
    }
    case 9: {
      return 13;
    }
    case 10: {
      return 15;
    }
    case 11: {
      return 17;
    }
    case 12: {
      return 19;
    }
    case 13: {
      return 23;
    }
    case 14: {
      return 27;
    }
    case 15: {
      return 31;
    }
    case 16: {
      return 35;
    }
    case 17: {
      return 43;
    }
    case 18: {
      return 51;
    }
    case 19: {
      return 59;
    }
    case 20: {
      return 67;
    }
    case 21: {
      return 83;
    }
    case 22: {
      return 99;
    }
    case 23: {
      return 115;
    }
    case 24: {
      return 131;
    }
    case 25: {
      return 163;
    }
    case 26: {
      return 195;
    }
    case 27: {
      return 227;
    }
    default: {
      return 258;
    }
  }
}
function _M0FP37walkzzz13image_2ecodec5codec10len__extra(i) {
  return i <= 7 ? 0 : i <= 11 ? 1 : i <= 15 ? 2 : i <= 19 ? 3 : i <= 23 ? 4 : i <= 27 ? 5 : 0;
}
function _M0MP37walkzzz13image_2ecodec5codec9BitWriter3put(self, value, nbits) {
  self.buf = self.buf | (value & ((1 << nbits) - 1 | 0)) << self.cnt;
  self.cnt = self.cnt + nbits | 0;
  while (true) {
    if (self.cnt >= 8) {
      _M0MPC15array5Array4pushGyE(self.out, self.buf & 255);
      self.buf = self.buf >> 8 & 16777215;
      self.cnt = self.cnt - 8 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0MP37walkzzz13image_2ecodec5codec9BitWriter9put__huff(self, code, nbits) {
  let rev = 0;
  let i = 0;
  while (true) {
    if (i < nbits) {
      rev = rev << 1 | code >> i & 1;
      i = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  _M0MP37walkzzz13image_2ecodec5codec9BitWriter3put(self, rev, nbits);
}
function _M0FP37walkzzz13image_2ecodec5codec11put__litlen(bw, sym) {
  if (sym <= 143) {
    _M0MP37walkzzz13image_2ecodec5codec9BitWriter9put__huff(bw, 48 + sym | 0, 8);
    return;
  } else {
    if (sym <= 255) {
      _M0MP37walkzzz13image_2ecodec5codec9BitWriter9put__huff(bw, 400 + (sym - 144 | 0) | 0, 9);
      return;
    } else {
      if (sym <= 279) {
        _M0MP37walkzzz13image_2ecodec5codec9BitWriter9put__huff(bw, sym - 256 | 0, 7);
        return;
      } else {
        _M0MP37walkzzz13image_2ecodec5codec9BitWriter9put__huff(bw, 192 + (sym - 280 | 0) | 0, 8);
        return;
      }
    }
  }
}
function _M0MP37walkzzz13image_2ecodec5codec9BitWriter6finish(self) {
  if (self.cnt > 0) {
    _M0MPC15array5Array4pushGyE(self.out, self.buf & 255);
    self.buf = 0;
    self.cnt = 0;
  }
  const _bind = self.out;
  return _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(_bind.buf, 0, _bind.len));
}
function _M0MP37walkzzz13image_2ecodec5codec9BitWriter3new() {
  return new _M0TP37walkzzz13image_2ecodec5codec9BitWriter(new _M0TPB5ArrayGyE(new Uint8Array([]), 0), 0, 0);
}
function _M0FP37walkzzz13image_2ecodec5codec14deflate__fixed(data) {
  const n = data.length;
  const bw = _M0MP37walkzzz13image_2ecodec5codec9BitWriter3new();
  _M0MP37walkzzz13image_2ecodec5codec9BitWriter3put(bw, 1, 1);
  _M0MP37walkzzz13image_2ecodec5codec9BitWriter3put(bw, 1, 2);
  const head = _M0MPC15array5Array4makeGiE(32768, -1);
  const prev = _M0MPC15array5Array4makeGiE(32768, -1);
  let pos = 0;
  while (true) {
    if (pos < n) {
      let best_len = 0;
      let best_dist = 0;
      if ((pos + 2 | 0) < n) {
        const h = _M0FP37walkzzz13image_2ecodec5codec5hash3(data, pos);
        if (h < 0 || h >= head.len) {
          $panic();
        }
        let cand = head.buf[h];
        let chain = 0;
        const max_match = (n - pos | 0) > 258 ? 258 : n - pos | 0;
        while (true) {
          if (cand >= 0 && (chain < 32 && (pos - cand | 0) <= 32768)) {
            let l = 0;
            while (true) {
              let _tmp;
              if (l < max_match) {
                const _tmp$2 = cand + l | 0;
                const _tmp$3 = _tmp$2 >>> 0 < data.length ? data[_tmp$2] : $oob();
                const _tmp$4 = pos + l | 0;
                _tmp = _tmp$3 === (_tmp$4 >>> 0 < data.length ? data[_tmp$4] : $oob());
              } else {
                _tmp = false;
              }
              if (_tmp) {
                l = l + 1 | 0;
                continue;
              } else {
                break;
              }
            }
            if (l > best_len && l >= 3) {
              best_len = l;
              best_dist = pos - cand | 0;
            }
            if (best_len >= max_match) {
              break;
            }
            const _bind = cand & 32767;
            if (_bind < 0 || _bind >= prev.len) {
              $panic();
            }
            cand = prev.buf[_bind];
            chain = chain + 1 | 0;
            continue;
          } else {
            break;
          }
        }
      }
      if (best_len >= 3) {
        let li = 0;
        while (true) {
          if (li < 28 && _M0FP37walkzzz13image_2ecodec5codec9len__base(li + 1 | 0) <= best_len) {
            li = li + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        _M0FP37walkzzz13image_2ecodec5codec11put__litlen(bw, 257 + li | 0);
        const eb = _M0FP37walkzzz13image_2ecodec5codec10len__extra(li);
        if (eb > 0) {
          _M0MP37walkzzz13image_2ecodec5codec9BitWriter3put(bw, best_len - _M0FP37walkzzz13image_2ecodec5codec9len__base(li) | 0, eb);
        }
        let di = 0;
        while (true) {
          if (di < 29 && _M0FP37walkzzz13image_2ecodec5codec10dist__base(di + 1 | 0) <= best_dist) {
            di = di + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        _M0MP37walkzzz13image_2ecodec5codec9BitWriter9put__huff(bw, di, 5);
        const _p = di;
        const deb = _p <= 3 ? 0 : (_p - 2 | 0) / 2 | 0;
        if (deb > 0) {
          _M0MP37walkzzz13image_2ecodec5codec9BitWriter3put(bw, best_dist - _M0FP37walkzzz13image_2ecodec5codec10dist__base(di) | 0, deb);
        }
        let k = 0;
        while (true) {
          if (k < best_len) {
            if (((pos + k | 0) + 2 | 0) < n) {
              const h2 = _M0FP37walkzzz13image_2ecodec5codec5hash3(data, pos + k | 0);
              const _bind = pos + k & 32767;
              if (h2 < 0 || h2 >= head.len) {
                $panic();
              }
              const _bind$2 = head.buf[h2];
              if (_bind < 0 || _bind >= prev.len) {
                $panic();
              }
              prev.buf[_bind] = _bind$2;
              const _bind$3 = pos + k | 0;
              if (h2 < 0 || h2 >= head.len) {
                $panic();
              }
              head.buf[h2] = _bind$3;
            }
            k = k + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        pos = pos + best_len | 0;
      } else {
        const _tmp = pos;
        _M0FP37walkzzz13image_2ecodec5codec11put__litlen(bw, _tmp >>> 0 < data.length ? data[_tmp] : $oob());
        if ((pos + 2 | 0) < n) {
          const h = _M0FP37walkzzz13image_2ecodec5codec5hash3(data, pos);
          const _bind = pos & 32767;
          if (h < 0 || h >= head.len) {
            $panic();
          }
          const _bind$2 = head.buf[h];
          if (_bind < 0 || _bind >= prev.len) {
            $panic();
          }
          prev.buf[_bind] = _bind$2;
          const _bind$3 = pos;
          if (h < 0 || h >= head.len) {
            $panic();
          }
          head.buf[h] = _bind$3;
        }
        pos = pos + 1 | 0;
      }
      continue;
    } else {
      break;
    }
  }
  _M0FP37walkzzz13image_2ecodec5codec11put__litlen(bw, 256);
  return _M0MP37walkzzz13image_2ecodec5codec9BitWriter6finish(bw);
}
function _M0FP37walkzzz13image_2ecodec5codec14zlib__compress(data) {
  const body = _M0FP37walkzzz13image_2ecodec5codec14deflate__fixed(data);
  const out = new _M0TPB5ArrayGyE(new Uint8Array([]), 0);
  _M0MPC15array5Array4pushGyE(out, 120);
  _M0MPC15array5Array4pushGyE(out, 156);
  const _bind = body.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      _M0MPC15array5Array4pushGyE(out, i >>> 0 < body.length ? body[i] : $oob());
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const adler = _M0FP37walkzzz13image_2ecodec4util7adler32(data);
  _M0MPC15array5Array4pushGyE(out, adler >> 24 & 255);
  _M0MPC15array5Array4pushGyE(out, adler >> 16 & 255);
  _M0MPC15array5Array4pushGyE(out, adler >> 8 & 255);
  _M0MPC15array5Array4pushGyE(out, adler & 255);
  return _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(out.buf, 0, out.len));
}
function _M0FP37walkzzz13image_2ecodec5codec17encode__png__pure(img) {
  const width = img.width;
  const height = img.height;
  const ch = img.channels;
  const out_ch = ch === 4 ? 4 : ch === 2 ? 2 : ch === 1 ? 1 : 3;
  const color_type = out_ch === 1 ? 0 : out_ch === 2 ? 4 : out_ch === 4 ? 6 : 2;
  const out = new _M0TPB5ArrayGyE(new Uint8Array([]), 0);
  _M0MPC15array5Array4pushGyE(out, 137);
  _M0MPC15array5Array4pushGyE(out, 80);
  _M0MPC15array5Array4pushGyE(out, 78);
  _M0MPC15array5Array4pushGyE(out, 71);
  _M0MPC15array5Array4pushGyE(out, 13);
  _M0MPC15array5Array4pushGyE(out, 10);
  _M0MPC15array5Array4pushGyE(out, 26);
  _M0MPC15array5Array4pushGyE(out, 10);
  const ihdr = new _M0TPB5ArrayGyE(new Uint8Array([]), 0);
  _M0MPC15array5Array4pushGyE(ihdr, width >> 24 & 255);
  _M0MPC15array5Array4pushGyE(ihdr, width >> 16 & 255);
  _M0MPC15array5Array4pushGyE(ihdr, width >> 8 & 255);
  _M0MPC15array5Array4pushGyE(ihdr, width & 255);
  _M0MPC15array5Array4pushGyE(ihdr, height >> 24 & 255);
  _M0MPC15array5Array4pushGyE(ihdr, height >> 16 & 255);
  _M0MPC15array5Array4pushGyE(ihdr, height >> 8 & 255);
  _M0MPC15array5Array4pushGyE(ihdr, height & 255);
  _M0MPC15array5Array4pushGyE(ihdr, 8);
  _M0MPC15array5Array4pushGyE(ihdr, color_type & 255);
  _M0MPC15array5Array4pushGyE(ihdr, 0);
  _M0MPC15array5Array4pushGyE(ihdr, 0);
  _M0MPC15array5Array4pushGyE(ihdr, 0);
  _M0FP37walkzzz13image_2ecodec5codec12write__chunk(out, "IHDR", _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(ihdr.buf, 0, ihdr.len)));
  const row_len = Math.imul(width, out_ch) | 0;
  const filtered = new _M0TPB5ArrayGyE(new Uint8Array([]), 0);
  const prev_row = _M0MPC15array5Array4makeGyE(row_len, 0);
  let _tmp = 0;
  while (true) {
    const y = _tmp;
    if (y < height) {
      const raw = _M0MPC15array5Array4makeGyE(row_len, 0);
      let _tmp$2 = 0;
      while (true) {
        const x = _tmp$2;
        if (x < width) {
          const src_off = Math.imul((Math.imul(y, width) | 0) + x | 0, ch) | 0;
          if (ch === out_ch) {
            let _tmp$3 = 0;
            while (true) {
              const c = _tmp$3;
              if (c < ch) {
                const _bind = (Math.imul(x, out_ch) | 0) + c | 0;
                const _tmp$4 = img.data;
                const _tmp$5 = src_off + c | 0;
                const _bind$2 = _tmp$5 >>> 0 < _tmp$4.length ? _tmp$4[_tmp$5] : $oob();
                if (_bind < 0 || _bind >= raw.len) {
                  $panic();
                }
                raw.buf[_bind] = _bind$2;
                _tmp$3 = c + 1 | 0;
                continue;
              } else {
                break;
              }
            }
          } else {
            let _tmp$3 = 0;
            while (true) {
              const c = _tmp$3;
              if (c < out_ch) {
                const _bind = (Math.imul(x, out_ch) | 0) + c | 0;
                let _bind$2;
                if (c < ch) {
                  const _tmp$4 = img.data;
                  const _tmp$5 = src_off + c | 0;
                  _bind$2 = _tmp$5 >>> 0 < _tmp$4.length ? _tmp$4[_tmp$5] : $oob();
                } else {
                  _bind$2 = 255;
                }
                if (_bind < 0 || _bind >= raw.len) {
                  $panic();
                }
                raw.buf[_bind] = _bind$2;
                _tmp$3 = c + 1 | 0;
                continue;
              } else {
                break;
              }
            }
          }
          _tmp$2 = x + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let best_type = 0;
      let best_score = 2147483647;
      let best_row = raw;
      let _tmp$3 = 0;
      while (true) {
        const ft = _tmp$3;
        if (ft < 5) {
          const cand = _M0FP37walkzzz13image_2ecodec5codec16png__filter__row(raw, prev_row, out_ch, ft);
          const score = _M0FP37walkzzz13image_2ecodec5codec18png__filter__score(cand);
          if (score < best_score) {
            best_score = score;
            best_type = ft;
            best_row = cand;
          }
          _tmp$3 = ft + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0MPC15array5Array4pushGyE(filtered, best_type & 255);
      let _tmp$4 = 0;
      while (true) {
        const i = _tmp$4;
        if (i < row_len) {
          const _bind = best_row;
          if (i < 0 || i >= _bind.len) {
            $panic();
          }
          _M0MPC15array5Array4pushGyE(filtered, _bind.buf[i]);
          _tmp$4 = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let _tmp$5 = 0;
      while (true) {
        const i = _tmp$5;
        if (i < row_len) {
          if (i < 0 || i >= raw.len) {
            $panic();
          }
          const _bind = raw.buf[i];
          if (i < 0 || i >= prev_row.len) {
            $panic();
          }
          prev_row.buf[i] = _bind;
          _tmp$5 = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp = y + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const compressed = _M0FP37walkzzz13image_2ecodec5codec14zlib__compress(_M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(filtered.buf, 0, filtered.len)));
  _M0FP37walkzzz13image_2ecodec5codec12write__chunk(out, "IDAT", compressed);
  const _bind = new Uint8Array([]);
  _M0FP37walkzzz13image_2ecodec5codec12write__chunk(out, "IEND", _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(_bind, 0, 0)));
  return _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(out.buf, 0, out.len));
}
function _M0FP37walkzzz13image_2ecodec3lib14detect__format(data) {
  const len = data.length;
  if (len < 2) {
    return 18;
  }
  if (len >= 8 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 137 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 80 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 78 && ((3 >>> 0 < data.length ? data[3] : $oob()) === 71 && ((4 >>> 0 < data.length ? data[4] : $oob()) === 13 && ((5 >>> 0 < data.length ? data[5] : $oob()) === 10 && ((6 >>> 0 < data.length ? data[6] : $oob()) === 26 && (7 >>> 0 < data.length ? data[7] : $oob()) === 10)))))))) {
    if (_M0FP37walkzzz13image_2ecodec5codec16is__apng__format(data)) {
      return 14;
    }
    return 0;
  }
  if ((0 >>> 0 < data.length ? data[0] : $oob()) === 255 && (1 >>> 0 < data.length ? data[1] : $oob()) === 216) {
    return 1;
  }
  if ((0 >>> 0 < data.length ? data[0] : $oob()) === 66 && (1 >>> 0 < data.length ? data[1] : $oob()) === 77) {
    return 2;
  }
  if (len >= 4 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 113 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 111 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 105 && (3 >>> 0 < data.length ? data[3] : $oob()) === 102)))) {
    return 8;
  }
  if ((0 >>> 0 < data.length ? data[0] : $oob()) === 80 && ((1 >>> 0 < data.length ? data[1] : $oob()) >= 53 && (1 >>> 0 < data.length ? data[1] : $oob()) <= 54)) {
    return 7;
  }
  if (len >= 4 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 56 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 66 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 80 && (3 >>> 0 < data.length ? data[3] : $oob()) === 83)))) {
    return 5;
  }
  if (len >= 6 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 71 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 73 && (2 >>> 0 < data.length ? data[2] : $oob()) === 70))) {
    return 3;
  }
  if (len >= 10 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 35 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 63 && (2 >>> 0 < data.length ? data[2] : $oob()) === 82))) {
    return 6;
  }
  if (len >= 12 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 82 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 73 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 70 && ((3 >>> 0 < data.length ? data[3] : $oob()) === 70 && ((8 >>> 0 < data.length ? data[8] : $oob()) === 87 && ((9 >>> 0 < data.length ? data[9] : $oob()) === 69 && ((10 >>> 0 < data.length ? data[10] : $oob()) === 66 && (11 >>> 0 < data.length ? data[11] : $oob()) === 80)))))))) {
    return 9;
  }
  if (len >= 4 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 105 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 99 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 110 && (3 >>> 0 < data.length ? data[3] : $oob()) === 115)))) {
    return 13;
  }
  if ((0 >>> 0 < data.length ? data[0] : $oob()) === 73 && (1 >>> 0 < data.length ? data[1] : $oob()) === 73 || (0 >>> 0 < data.length ? data[0] : $oob()) === 77 && (1 >>> 0 < data.length ? data[1] : $oob()) === 77) {
    if (len >= 4 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 42 && (3 >>> 0 < data.length ? data[3] : $oob()) === 0 || (2 >>> 0 < data.length ? data[2] : $oob()) === 0 && (3 >>> 0 < data.length ? data[3] : $oob()) === 42)) {
      return 10;
    }
  }
  if (len >= 22 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 0 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 0 && (((2 >>> 0 < data.length ? data[2] : $oob()) === 1 || (2 >>> 0 < data.length ? data[2] : $oob()) === 2) && ((3 >>> 0 < data.length ? data[3] : $oob()) === 0 && (4 >>> 0 < data.length ? data[4] : $oob()) !== 0))))) {
    const width = 6 >>> 0 < data.length ? data[6] : $oob();
    const height = 7 >>> 0 < data.length ? data[7] : $oob();
    if ((2 >>> 0 < data.length ? data[2] : $oob()) === 2 && (width === 0 && height === 0)) {
      return 12;
    }
    return 11;
  }
  if (len >= 2 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 255 && (1 >>> 0 < data.length ? data[1] : $oob()) === 10)) {
    return 17;
  }
  if (len >= 12 && ((0 >>> 0 < data.length ? data[0] : $oob()) === 0 && ((1 >>> 0 < data.length ? data[1] : $oob()) === 0 && ((2 >>> 0 < data.length ? data[2] : $oob()) === 0 && ((3 >>> 0 < data.length ? data[3] : $oob()) === 12 && ((4 >>> 0 < data.length ? data[4] : $oob()) === 74 && ((5 >>> 0 < data.length ? data[5] : $oob()) === 88 && ((6 >>> 0 < data.length ? data[6] : $oob()) === 76 && (7 >>> 0 < data.length ? data[7] : $oob()) === 32)))))))) {
    return 17;
  }
  if (len >= 12 && ((4 >>> 0 < data.length ? data[4] : $oob()) === 102 && ((5 >>> 0 < data.length ? data[5] : $oob()) === 116 && ((6 >>> 0 < data.length ? data[6] : $oob()) === 121 && (7 >>> 0 < data.length ? data[7] : $oob()) === 112)))) {
    const b8 = 8 >>> 0 < data.length ? data[8] : $oob();
    const b9 = 9 >>> 0 < data.length ? data[9] : $oob();
    const b10 = 10 >>> 0 < data.length ? data[10] : $oob();
    const b11 = 11 >>> 0 < data.length ? data[11] : $oob();
    if (b8 === 97 && (b9 === 118 && (b10 === 105 && (b11 === 102 || b11 === 115)))) {
      return 15;
    }
    if (b8 === 104 && (b9 === 101 && (b10 === 105 && (b11 === 99 || b11 === 120))) || (b8 === 104 && (b9 === 101 && (b10 === 118 && b11 === 99)) || b8 === 109 && (b9 === 105 && (b10 === 102 && b11 === 49)))) {
      return 16;
    }
  }
  if (_M0FP37walkzzz13image_2ecodec5codec15is__tga__format(data)) {
    return 4;
  }
  return 18;
}
function _M0FP37walkzzz13image_2ecodec3lib16get__image__info(data) {
  const format = _M0FP37walkzzz13image_2ecodec3lib14detect__format(data);
  const _bind = _M0FP37walkzzz13image_2ecodec5codec26get__image__info__extended(data);
  let ext;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    ext = _ok._0;
  } else {
    return _bind;
  }
  let format_name;
  switch (format) {
    case 0: {
      format_name = "PNG";
      break;
    }
    case 1: {
      format_name = "JPEG";
      break;
    }
    case 2: {
      format_name = "BMP";
      break;
    }
    case 3: {
      format_name = "GIF";
      break;
    }
    case 4: {
      format_name = "TGA";
      break;
    }
    case 5: {
      format_name = "PSD";
      break;
    }
    case 6: {
      format_name = "HDR";
      break;
    }
    case 7: {
      format_name = "PNM";
      break;
    }
    case 8: {
      format_name = "QOI";
      break;
    }
    case 9: {
      format_name = "WebP";
      break;
    }
    case 10: {
      format_name = "TIFF";
      break;
    }
    case 11: {
      format_name = "ICO";
      break;
    }
    case 12: {
      format_name = "CUR";
      break;
    }
    case 13: {
      format_name = "ICNS";
      break;
    }
    case 14: {
      format_name = "APNG";
      break;
    }
    case 15: {
      format_name = "AVIF";
      break;
    }
    case 16: {
      format_name = "HEIF";
      break;
    }
    case 17: {
      format_name = "JPEG-XL";
      break;
    }
    case 18: {
      format_name = "unknown";
      break;
    }
    default: {
      format_name = "unknown";
    }
  }
  switch (ext.$tag) {
    case 0: {
      const _Avif = ext;
      const _e = _Avif._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e.width, _e.height, _e.num_channels, _e.bit_depth, _e.has_alpha));
    }
    case 1: {
      const _Heif = ext;
      const _e$2 = _Heif._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$2.width, _e$2.height, _e$2.num_channels, _e$2.bit_depth, _e$2.has_alpha));
    }
    case 2: {
      const _JpegXl = ext;
      const _e$3 = _JpegXl._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$3.width, _e$3.height, _e$3.num_channels, _e$3.bit_depth, _e$3.has_alpha));
    }
    case 3: {
      const _Webp = ext;
      const _e$4 = _Webp._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$4.width, _e$4.height, _e$4.num_channels, 8, _e$4.has_alpha));
    }
    case 4: {
      const _Tiff = ext;
      const _e$5 = _Tiff._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$5.width, _e$5.height, _e$5.num_channels, _e$5.bit_depth, _e$5.has_alpha));
    }
    case 5: {
      const _Psd = ext;
      const _e$6 = _Psd._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$6.width, _e$6.height, _e$6.num_channels, _e$6.bit_depth, _e$6.has_alpha));
    }
    case 6: {
      const _Bmp = ext;
      const _e$7 = _Bmp._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$7.width, _e$7.height, _e$7.num_channels, _e$7.bit_depth, _e$7.has_alpha));
    }
    case 7: {
      const _Gif = ext;
      const _e$8 = _Gif._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$8.width, _e$8.height, _e$8.num_channels, 8, _e$8.has_alpha));
    }
    case 8: {
      const _Png = ext;
      const _e$9 = _Png._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$9.width, _e$9.height, _e$9.num_channels, _e$9.bit_depth, _e$9.has_alpha));
    }
    case 9: {
      const _Jpeg = ext;
      const _e$10 = _Jpeg._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$10.width, _e$10.height, _e$10.num_channels, _e$10.precision, _e$10.has_alpha));
    }
    case 10: {
      const _Qoi = ext;
      const _e$11 = _Qoi._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$11.width, _e$11.height, _e$11.num_channels, 8, _e$11.has_alpha));
    }
    case 11: {
      const _Tga = ext;
      const _e$12 = _Tga._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$12.width, _e$12.height, _e$12.num_channels, _e$12.bit_depth, _e$12.has_alpha));
    }
    case 12: {
      const _Hdr = ext;
      const _e$13 = _Hdr._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$13.width, _e$13.height, _e$13.num_channels, 32, _e$13.has_alpha));
    }
    case 13: {
      const _Pnm = ext;
      const _e$14 = _Pnm._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$14.width, _e$14.height, _e$14.num_channels, _e$14.bit_depth, _e$14.has_alpha));
    }
    case 14: {
      const _Ico = ext;
      const _e$15 = _Ico._0;
      const _tmp = _e$15.width;
      const _tmp$2 = _e$15.height;
      const _tmp$3 = _e$15.num_channels;
      let _tmp$4;
      if (_e$15.bit_depths.len > 0) {
        const _bind$2 = _e$15.bit_depths;
        if (0 >= _bind$2.len) {
          $panic();
        }
        _tmp$4 = _bind$2.buf[0];
      } else {
        _tmp$4 = 0;
      }
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _tmp, _tmp$2, _tmp$3, _tmp$4, _e$15.has_alpha));
    }
    case 15: {
      const _Cur = ext;
      const _e$16 = _Cur._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$16.width, _e$16.height, _e$16.num_channels, 8, _e$16.has_alpha));
    }
    case 16: {
      const _Icns = ext;
      const _e$17 = _Icns._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$17.width, _e$17.height, _e$17.num_channels, 32, _e$17.has_alpha));
    }
    case 17: {
      const _Apng = ext;
      const _e$18 = _Apng._0;
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, format_name, _e$18.width, _e$18.height, _e$18.num_channels, _e$18.bit_depth, _e$18.has_alpha));
    }
    default: {
      return new _M0DTPC16result6ResultGRP37walkzzz13image_2ecodec3lib16UnifiedImageInfoRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz13image_2ecodec3lib16UnifiedImageInfo(format, "unknown", 0, 0, 0, 0, false));
    }
  }
}
function _M0FP37walkzzz13image_2ecodec3lib19get__image__summary(data) {
  const _bind = _M0FP37walkzzz13image_2ecodec3lib16get__image__info(data);
  let info;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    info = _ok._0;
  } else {
    return _bind;
  }
  return new _M0DTPC16result6ResultGsRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(`${info.format_name} ${_M0MPC13int3Int18to__string_2einner(info.width, 10)}x${_M0MPC13int3Int18to__string_2einner(info.height, 10)} ${_M0MPC13int3Int18to__string_2einner(info.channels, 10)}ch ${_M0MPC13int3Int18to__string_2einner(info.bit_depth, 10)}bit`);
}
function _M0FP37walkzzz13image_2ecodec3lib11encode__png(img) {
  return _M0FP37walkzzz13image_2ecodec5codec17encode__png__pure(img);
}
function _M0FP37walkzzz12image_2ecore7testgen11qr__gf__mul(a, b) {
  let x = a & 255;
  let y = b & 255;
  let r = 0;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < 8) {
      if ((y & 1) === 1) {
        r = r ^ x;
      }
      x = x << 1;
      if ((x & 256) !== 0) {
        x = x ^ 285;
      }
      y = y >> 1;
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return r & 255;
}
function _M0FP37walkzzz12image_2ecore7testgen11qr__gf__pow(base, exp) {
  let r = 1;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < exp) {
      r = _M0FP37walkzzz12image_2ecore7testgen11qr__gf__mul(r, base);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return r;
}
function _M0FP37walkzzz12image_2ecore7testgen14qr__rs__encode(data, ecc_len) {
  let gen = new _M0TPB5ArrayGiE([1], 1);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < ecc_len) {
      const alpha = _M0FP37walkzzz12image_2ecore7testgen11qr__gf__pow(2, i);
      const next = _M0MPC15array5Array4makeGiE(gen.len + 1 | 0, 0);
      const _bind = gen.len;
      let _tmp$2 = 0;
      while (true) {
        const j = _tmp$2;
        if (j < _bind) {
          if (j < 0 || j >= next.len) {
            $panic();
          }
          const _tmp$3 = next.buf[j];
          const _bind$2 = gen;
          if (j < 0 || j >= _bind$2.len) {
            $panic();
          }
          const _bind$3 = _tmp$3 ^ _bind$2.buf[j];
          if (j < 0 || j >= next.len) {
            $panic();
          }
          next.buf[j] = _bind$3;
          const _bind$4 = j + 1 | 0;
          const _bind$5 = j + 1 | 0;
          if (_bind$5 < 0 || _bind$5 >= next.len) {
            $panic();
          }
          const _tmp$4 = next.buf[_bind$5];
          const _bind$6 = gen;
          if (j < 0 || j >= _bind$6.len) {
            $panic();
          }
          const _bind$7 = _tmp$4 ^ _M0FP37walkzzz12image_2ecore7testgen11qr__gf__mul(_bind$6.buf[j], alpha);
          if (_bind$4 < 0 || _bind$4 >= next.len) {
            $panic();
          }
          next.buf[_bind$4] = _bind$7;
          _tmp$2 = j + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      gen = next;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const rem = _M0MPC15array5Array4makeGiE(ecc_len, 0);
  const _bind = data.len;
  const _bind$2 = data.buf;
  let _tmp$2 = 0;
  while (true) {
    const _ = _tmp$2;
    if (_ < _bind) {
      const b = _bind$2[_];
      const _tmp$3 = b & 255;
      if (0 >= rem.len) {
        $panic();
      }
      const factor = _tmp$3 ^ rem.buf[0];
      let _tmp$4 = 1;
      while (true) {
        const i = _tmp$4;
        if (i < ecc_len) {
          const _bind$3 = i - 1 | 0;
          if (i < 0 || i >= rem.len) {
            $panic();
          }
          const _bind$4 = rem.buf[i];
          if (_bind$3 < 0 || _bind$3 >= rem.len) {
            $panic();
          }
          rem.buf[_bind$3] = _bind$4;
          _tmp$4 = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _bind$3 = ecc_len - 1 | 0;
      if (_bind$3 < 0 || _bind$3 >= rem.len) {
        $panic();
      }
      rem.buf[_bind$3] = 0;
      let _tmp$5 = 0;
      while (true) {
        const i = _tmp$5;
        if (i < ecc_len) {
          if (i < 0 || i >= rem.len) {
            $panic();
          }
          const _tmp$6 = rem.buf[i];
          const _bind$4 = gen;
          const _bind$5 = i + 1 | 0;
          if (_bind$5 < 0 || _bind$5 >= _bind$4.len) {
            $panic();
          }
          const _bind$6 = _tmp$6 ^ _M0FP37walkzzz12image_2ecore7testgen11qr__gf__mul(_bind$4.buf[_bind$5], factor);
          if (i < 0 || i >= rem.len) {
            $panic();
          }
          rem.buf[i] = _bind$6;
          _tmp$5 = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp$2 = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return rem;
}
function _M0FP37walkzzz12image_2ecore7testgen16qr__format__bits(ec_level, mask) {
  const data = (ec_level & 3) << 3 | mask & 7;
  let rem = data << 10;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < 5) {
      if ((rem >> (14 - i | 0) & 1) === 1) {
        rem = rem ^ 1335 << (4 - i | 0);
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return ((data << 10 | rem & 1023) ^ 21522) & 32767;
}
function _M0FP37walkzzz12image_2ecore7testgen12qr__l__block(version) {
  switch (version) {
    case 1: {
      return _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1337;
    }
    case 2: {
      return _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1338;
    }
    case 3: {
      return _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1339;
    }
    case 4: {
      return _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1340;
    }
    case 5: {
      return _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1341;
    }
    default: {
      return _M0FP37walkzzz12image_2ecore7testgen12qr__l__blockN5tupleS1342;
    }
  }
}
function _M0FP37walkzzz12image_2ecore7testgen18qr__byte__capacity(version) {
  const _bind = _M0FP37walkzzz12image_2ecore7testgen12qr__l__block(version);
  const _data_codes = _bind._0;
  return ((Math.imul(_data_codes, 8) | 0) - 12 | 0) / 8 | 0;
}
function _M0FP37walkzzz12image_2ecore7testgen17qr__pick__version(payload_len) {
  let v = 1;
  while (true) {
    if (v < 5 && payload_len > _M0FP37walkzzz12image_2ecore7testgen18qr__byte__capacity(v)) {
      v = v + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return v;
}
function _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, idx, v) {
  const is_func = _env._1;
  const modules = _env._0;
  if (idx < 0 || idx >= modules.len) {
    $panic();
  }
  modules.buf[idx] = v;
  if (idx < 0 || idx >= is_func.len) {
    $panic();
  }
  is_func.buf[idx] = true;
}
function _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__v(payload, version) {
  const size = 17 + (Math.imul(4, version) | 0) | 0;
  const _bind = _M0FP37walkzzz12image_2ecore7testgen12qr__l__block(version);
  const _data_codes_len = _bind._0;
  const _ecc_len = _bind._1;
  const modules = _M0MPC15array5Array4makeGiE(Math.imul(size, size) | 0, 0);
  const is_func = _M0MPC15array5Array4makeGbE(Math.imul(size, size) | 0, false);
  const _env = { _0: modules, _1: is_func };
  let finder_pos_buf = [_M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1352, { _0: 0, _1: size - 7 | 0 }, { _0: size - 7 | 0, _1: 0 }];
  let finder_pos_len = 3;
  const _bind$2 = finder_pos_len;
  const _bind$3 = finder_pos_buf;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind$2) {
      const _foreach_element = _bind$3[_];
      const _fr = _foreach_element._0;
      const _fc = _foreach_element._1;
      let _tmp$2 = -1;
      while (true) {
        const r = _tmp$2;
        if (r < 8) {
          let _tmp$3 = -1;
          while (true) {
            const c = _tmp$3;
            if (c < 8) {
              const rr = _fr + r | 0;
              const cc = _fc + c | 0;
              if (rr >= 0 && (rr < size && (cc >= 0 && cc < size))) {
                const in_core = r >= 0 && (r <= 6 && (c >= 0 && c <= 6));
                let v = 0;
                if (in_core) {
                  const border = r === 0 || (r === 6 || (c === 0 || c === 6));
                  const center = r >= 2 && (r <= 4 && (c >= 2 && c <= 4));
                  v = border || center ? 1 : 0;
                }
                _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, (Math.imul(rr, size) | 0) + cc | 0, v);
              }
              _tmp$3 = c + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          _tmp$2 = r + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _bind$4 = size - 8 | 0;
  let _tmp$2 = 8;
  while (true) {
    const i = _tmp$2;
    if (i < _bind$4) {
      _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, (Math.imul(6, size) | 0) + i | 0, (i % 2 | 0) === 0 ? 1 : 0);
      _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, (Math.imul(i, size) | 0) + 6 | 0, (i % 2 | 0) === 0 ? 1 : 0);
      _tmp$2 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (version >= 2) {
    const cr = size - 7 | 0;
    const cc = size - 7 | 0;
    let _tmp$3 = -2;
    while (true) {
      const dr = _tmp$3;
      if (dr < 3) {
        let _tmp$4 = -2;
        while (true) {
          const dc = _tmp$4;
          if (dc < 3) {
            const rr = cr + dr | 0;
            const c2 = cc + dc | 0;
            const ring = dr === -2 || (dr === 2 || (dc === -2 || dc === 2));
            const center = dr === 0 && dc === 0;
            _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, (Math.imul(rr, size) | 0) + c2 | 0, ring || center ? 1 : 0);
            _tmp$4 = dc + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        _tmp$3 = dr + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, (Math.imul(size - 8 | 0, size) | 0) + 8 | 0, 1);
  let fmt_pos_a_buf = [_M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1353, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1354, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1355, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1356, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1357, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1358, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1359, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1360, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1361, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1362, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1363, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1364, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1365, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1366, _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN5tupleS1367];
  let fmt_pos_a_len = 15;
  const _bind$5 = fmt_pos_a_len;
  const _bind$6 = fmt_pos_a_buf;
  let _tmp$3 = 0;
  while (true) {
    const _ = _tmp$3;
    if (_ < _bind$5) {
      const _foreach_element = _bind$6[_];
      const _r = _foreach_element._0;
      const _c = _foreach_element._1;
      _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, (Math.imul(_r, size) | 0) + _c | 0, 0);
      _tmp$3 = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let _tmp$4 = 0;
  while (true) {
    const i = _tmp$4;
    if (i < 7) {
      _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, (Math.imul((size - 1 | 0) - i | 0, size) | 0) + 8 | 0, 0);
      _tmp$4 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let _tmp$5 = 0;
  while (true) {
    const i = _tmp$5;
    if (i < 8) {
      _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__vN3setS1351(_env, (Math.imul(8, size) | 0) + ((size - 8 | 0) + i | 0) | 0, 0);
      _tmp$5 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const bits = new _M0TPB5ArrayGiE([], 0);
  _M0MPC15array5Array4pushGiE(bits, 0);
  _M0MPC15array5Array4pushGiE(bits, 1);
  _M0MPC15array5Array4pushGiE(bits, 0);
  _M0MPC15array5Array4pushGiE(bits, 0);
  let _tmp$6 = 0;
  while (true) {
    const i = _tmp$6;
    if (i < 8) {
      _M0MPC15array5Array4pushGiE(bits, payload.length >> (7 - i | 0) & 1);
      _tmp$6 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _bind$7 = payload.length;
  let _tmp$7 = 0;
  while (true) {
    const i = _tmp$7;
    if (i < _bind$7) {
      const b = i >>> 0 < payload.length ? payload[i] : $oob();
      let _tmp$8 = 0;
      while (true) {
        const k = _tmp$8;
        if (k < 8) {
          _M0MPC15array5Array4pushGiE(bits, b >> (7 - k | 0) & 1);
          _tmp$8 = k + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp$7 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const data_capacity = Math.imul(_data_codes_len, 8) | 0;
  if (bits.len > data_capacity) {
    while (true) {
      if (bits.len > data_capacity) {
        _M0MPC15array5Array3popGiE(bits);
        continue;
      } else {
        break;
      }
    }
  }
  let _tmp$8 = 0;
  while (true) {
    const _ = _tmp$8;
    if (_ < 4) {
      if (bits.len < data_capacity) {
        _M0MPC15array5Array4pushGiE(bits, 0);
      }
      _tmp$8 = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  while (true) {
    if ((bits.len % 8 | 0) !== 0) {
      _M0MPC15array5Array4pushGiE(bits, 0);
      continue;
    } else {
      break;
    }
  }
  let pad_toggle = true;
  while (true) {
    if (bits.len < data_capacity) {
      const byte_val = pad_toggle ? 236 : 17;
      let _tmp$9 = 0;
      while (true) {
        const k = _tmp$9;
        if (k < 8) {
          _M0MPC15array5Array4pushGiE(bits, byte_val >> (7 - k | 0) & 1);
          _tmp$9 = k + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      pad_toggle = !pad_toggle;
      continue;
    } else {
      break;
    }
  }
  const data_codes = _M0MPC15array5Array4makeGiE(_data_codes_len, 0);
  let _tmp$9 = 0;
  while (true) {
    const i = _tmp$9;
    if (i < _data_codes_len) {
      let v = 0;
      let _tmp$10 = 0;
      while (true) {
        const k = _tmp$10;
        if (k < 8) {
          const _tmp$11 = v << 1;
          const _bind$8 = (Math.imul(i, 8) | 0) + k | 0;
          if (_bind$8 < 0 || _bind$8 >= bits.len) {
            $panic();
          }
          v = _tmp$11 | bits.buf[_bind$8];
          _tmp$10 = k + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _bind$8 = v;
      if (i < 0 || i >= data_codes.len) {
        $panic();
      }
      data_codes.buf[i] = _bind$8;
      _tmp$9 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const ecc = _M0FP37walkzzz12image_2ecore7testgen14qr__rs__encode(data_codes, _ecc_len);
  const all_codes = new _M0TPB5ArrayGiE([], 0);
  const _bind$8 = data_codes.len;
  const _bind$9 = data_codes.buf;
  let _tmp$10 = 0;
  while (true) {
    const _ = _tmp$10;
    if (_ < _bind$8) {
      const c = _bind$9[_];
      _M0MPC15array5Array4pushGiE(all_codes, c);
      _tmp$10 = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _bind$10 = ecc.len;
  const _bind$11 = ecc.buf;
  let _tmp$11 = 0;
  while (true) {
    const _ = _tmp$11;
    if (_ < _bind$10) {
      const c = _bind$11[_];
      _M0MPC15array5Array4pushGiE(all_codes, c);
      _tmp$11 = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let bit_idx = 0;
  const total_bits = Math.imul(all_codes.len, 8) | 0;
  let col = size - 1 | 0;
  let upward = true;
  while (true) {
    if (col > 0) {
      if (col === 6) {
        col = col - 1 | 0;
      }
      let _tmp$12 = 0;
      while (true) {
        const step = _tmp$12;
        if (step < size) {
          const r = upward ? (size - 1 | 0) - step | 0 : step;
          let _tmp$13 = 0;
          while (true) {
            const dc = _tmp$13;
            if (dc < 2) {
              const c = col - dc | 0;
              const idx = (Math.imul(r, size) | 0) + c | 0;
              if (idx < 0 || idx >= is_func.len) {
                $panic();
              }
              if (!is_func.buf[idx]) {
                let bit;
                if (bit_idx < total_bits) {
                  const _bind$12 = bit_idx / 8 | 0;
                  if (_bind$12 < 0 || _bind$12 >= all_codes.len) {
                    $panic();
                  }
                  const byte = all_codes.buf[_bind$12];
                  bit = byte >> (7 - (bit_idx % 8 | 0) | 0) & 1;
                } else {
                  bit = 0;
                }
                if (idx < 0 || idx >= modules.len) {
                  $panic();
                }
                modules.buf[idx] = bit;
                bit_idx = bit_idx + 1 | 0;
              }
              _tmp$13 = dc + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          _tmp$12 = step + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      upward = !upward;
      col = col - 2 | 0;
      continue;
    } else {
      break;
    }
  }
  let _tmp$12 = 0;
  while (true) {
    const r = _tmp$12;
    if (r < size) {
      let _tmp$13 = 0;
      while (true) {
        const c = _tmp$13;
        if (c < size) {
          const idx = (Math.imul(r, size) | 0) + c | 0;
          let _tmp$14;
          if (idx < 0 || idx >= is_func.len) {
            $panic();
          }
          if (!is_func.buf[idx]) {
            _tmp$14 = ((r + c | 0) % 2 | 0) === 0;
          } else {
            _tmp$14 = false;
          }
          if (_tmp$14) {
            let _bind$12;
            if (idx < 0 || idx >= modules.len) {
              $panic();
            }
            if (modules.buf[idx] === 1) {
              _bind$12 = 0;
            } else {
              _bind$12 = 1;
            }
            if (idx < 0 || idx >= modules.len) {
              $panic();
            }
            modules.buf[idx] = _bind$12;
          }
          _tmp$13 = c + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp$12 = r + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const fmt = _M0FP37walkzzz12image_2ecore7testgen16qr__format__bits(1, 0);
  let _tmp$13 = 0;
  while (true) {
    const i = _tmp$13;
    if (i < 15) {
      const bit = fmt >> (14 - i | 0) & 1;
      if (i < 0 || i >= fmt_pos_a_len) {
        $panic();
      }
      const _bind$12 = fmt_pos_a_buf[i];
      const _r = _bind$12._0;
      const _c = _bind$12._1;
      const _bind$13 = (Math.imul(_r, size) | 0) + _c | 0;
      if (_bind$13 < 0 || _bind$13 >= modules.len) {
        $panic();
      }
      modules.buf[_bind$13] = bit;
      _tmp$13 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let _tmp$14 = 0;
  while (true) {
    const i = _tmp$14;
    if (i < 8) {
      const bit = fmt >> i & 1;
      const _bind$12 = (Math.imul(8, size) | 0) + ((size - 1 | 0) - i | 0) | 0;
      if (_bind$12 < 0 || _bind$12 >= modules.len) {
        $panic();
      }
      modules.buf[_bind$12] = bit;
      _tmp$14 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let _tmp$15 = 8;
  while (true) {
    const i = _tmp$15;
    if (i < 15) {
      const bit = fmt >> i & 1;
      const _bind$12 = (Math.imul((size - 15 | 0) + i | 0, size) | 0) + 8 | 0;
      if (_bind$12 < 0 || _bind$12 >= modules.len) {
        $panic();
      }
      modules.buf[_bind$12] = bit;
      _tmp$15 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return { _0: size, _1: modules };
}
function _M0FP37walkzzz12image_2ecore7testgen18render__qr_2einner(payload, module_px, quiet_zone) {
  const version = _M0FP37walkzzz12image_2ecore7testgen17qr__pick__version(payload.length);
  const _bind = _M0FP37walkzzz12image_2ecore7testgen20qr__build__matrix__v(payload, version);
  const _size = _bind._0;
  const _modules = _bind._1;
  const mp = module_px < 1 ? 1 : module_px;
  const qz = quiet_zone < 0 ? 0 : quiet_zone;
  const px = Math.imul(_size + (Math.imul(2, qz) | 0) | 0, mp) | 0;
  const data = _M0MPC15array5Array4makeGyE(Math.imul(px, px) | 0, 255);
  let _tmp = 0;
  while (true) {
    const r = _tmp;
    if (r < _size) {
      let _tmp$2 = 0;
      while (true) {
        const c = _tmp$2;
        if (c < _size) {
          const _bind$2 = (Math.imul(r, _size) | 0) + c | 0;
          if (_bind$2 < 0 || _bind$2 >= _modules.len) {
            $panic();
          }
          if (_modules.buf[_bind$2] === 1) {
            let _tmp$3 = 0;
            while (true) {
              const dy = _tmp$3;
              if (dy < mp) {
                let _tmp$4 = 0;
                while (true) {
                  const dx = _tmp$4;
                  if (dx < mp) {
                    const y = (Math.imul(r + qz | 0, mp) | 0) + dy | 0;
                    const x = (Math.imul(c + qz | 0, mp) | 0) + dx | 0;
                    const _bind$3 = (Math.imul(y, px) | 0) + x | 0;
                    if (_bind$3 < 0 || _bind$3 >= data.len) {
                      $panic();
                    }
                    data.buf[_bind$3] = 0;
                    _tmp$4 = dx + 1 | 0;
                    continue;
                  } else {
                    break;
                  }
                }
                _tmp$3 = dy + 1 | 0;
                continue;
              } else {
                break;
              }
            }
          }
          _tmp$2 = c + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp = r + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP37walkzzz12image_2ecore5types5Image(px, px, 1, _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(data.buf, 0, data.len)));
}
function _M0FP37walkzzz12image_2ecore7testgen14qr__max__bytes() {
  return _M0FP37walkzzz12image_2ecore7testgen18qr__byte__capacity(5);
}
function _M0FP37walkzzz12image_2ecore7testgen8qr__fits(payload) {
  return payload.length <= _M0FP37walkzzz12image_2ecore7testgen14qr__max__bytes();
}
function _M0FP37walkzzz15image_2eprocess5color18adjust__brightness(img, delta) {
  if (img.width <= 0 || img.height <= 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("adjust_brightness: 图像尺寸必须大于0"));
  }
  if (img.channels < 1 || img.channels > 4) {
    return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("adjust_brightness: 通道数必须在1-4之间"));
  }
  const expected_size = Math.imul(Math.imul(img.width, img.height) | 0, img.channels) | 0;
  if (img.data.length !== expected_size) {
    return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed(`adjust_brightness: 数据大小不匹配，期望 ${_M0MPC13int3Int18to__string_2einner(expected_size, 10)}，实际 ${_M0MPC13int3Int18to__string_2einner(img.data.length, 10)}`));
  }
  const n = Math.imul(img.width, img.height) | 0;
  const ch = img.channels;
  const color_ch = ch >= 3 ? 3 : ch;
  const lut = _M0MPC15array5Array4makeGyE(256, 0);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < 256) {
      const _bind = _M0FP37walkzzz12image_2ecore5types11clamp__byte(i + delta | 0);
      if (i < 0 || i >= lut.len) {
        $panic();
      }
      lut.buf[i] = _bind;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const out = _M0MPC15array5Array4makeGyE(Math.imul(n, ch) | 0, 0);
  let _tmp$2 = 0;
  while (true) {
    const i = _tmp$2;
    if (i < n) {
      let _tmp$3 = 0;
      while (true) {
        const c = _tmp$3;
        if (c < color_ch) {
          const _bind = (Math.imul(i, ch) | 0) + c | 0;
          const _tmp$4 = img.data;
          const _tmp$5 = (Math.imul(i, ch) | 0) + c | 0;
          const _bind$2 = _tmp$5 >>> 0 < _tmp$4.length ? _tmp$4[_tmp$5] : $oob();
          if (_bind$2 < 0 || _bind$2 >= lut.len) {
            $panic();
          }
          const _bind$3 = lut.buf[_bind$2];
          if (_bind < 0 || _bind >= out.len) {
            $panic();
          }
          out.buf[_bind] = _bind$3;
          _tmp$3 = c + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      if (ch === 4) {
        const _bind = (Math.imul(i, ch) | 0) + 3 | 0;
        const _tmp$4 = img.data;
        const _tmp$5 = (Math.imul(i, ch) | 0) + 3 | 0;
        const _bind$2 = _tmp$5 >>> 0 < _tmp$4.length ? _tmp$4[_tmp$5] : $oob();
        if (_bind < 0 || _bind >= out.len) {
          $panic();
        }
        out.buf[_bind] = _bind$2;
      }
      _tmp$2 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz12image_2ecore5types5Image(img.width, img.height, ch, _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(out.buf, 0, out.len))));
}
function _M0FP37walkzzz15image_2eprocess6filter9box__blur(img, radius) {
  if (img.width <= 0 || img.height <= 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("box_blur: 图像尺寸必须大于0"));
  }
  if (img.channels < 1 || img.channels > 4) {
    return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("box_blur: 通道数必须在1-4之间"));
  }
  const expected_size = Math.imul(Math.imul(img.width, img.height) | 0, img.channels) | 0;
  if (img.data.length !== expected_size) {
    return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed(`box_blur: 数据大小不匹配，期望 ${_M0MPC13int3Int18to__string_2einner(expected_size, 10)}，实际 ${_M0MPC13int3Int18to__string_2einner(img.data.length, 10)}`));
  }
  if (radius < 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE3Err(new _M0DTPC15error5Error57walkzzz_2fimage_2ecore_2ftypes_2eLoadError_2eDecodeFailed("box_blur: radius不能为负"));
  }
  if (radius <= 0) {
    return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(img);
  }
  const w = img.width;
  const h = img.height;
  const ch = img.channels;
  const color_ch = ch >= 3 ? 3 : ch;
  const n = Math.imul(w, h) | 0;
  const win_size = (Math.imul(2, radius) | 0) + 1 | 0;
  const temp = _M0MPC15array5Array4makeGiE(Math.imul(n, color_ch) | 0, 0);
  let _tmp = 0;
  while (true) {
    const y = _tmp;
    if (y < h) {
      let _tmp$2 = 0;
      while (true) {
        const c = _tmp$2;
        if (c < color_ch) {
          let sum = 0;
          let _tmp$3 = 0;
          while (true) {
            const dx = _tmp$3;
            if (dx < win_size) {
              const x = _M0FP37walkzzz12image_2ecore5types12clamp__coord(dx - radius | 0, w);
              const _tmp$4 = sum;
              const _tmp$5 = img.data;
              const _tmp$6 = (Math.imul((Math.imul(y, w) | 0) + x | 0, ch) | 0) + c | 0;
              sum = _tmp$4 + (_tmp$6 >>> 0 < _tmp$5.length ? _tmp$5[_tmp$6] : $oob()) | 0;
              _tmp$3 = dx + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          let _tmp$4 = 0;
          while (true) {
            const x = _tmp$4;
            if (x < w) {
              const _bind = (Math.imul((Math.imul(y, w) | 0) + x | 0, color_ch) | 0) + c | 0;
              const _bind$2 = sum / win_size | 0;
              if (_bind < 0 || _bind >= temp.len) {
                $panic();
              }
              temp.buf[_bind] = _bind$2;
              const x_out = _M0FP37walkzzz12image_2ecore5types12clamp__coord(x - radius | 0, w);
              const x_in = _M0FP37walkzzz12image_2ecore5types12clamp__coord((x + radius | 0) + 1 | 0, w);
              const _tmp$5 = sum;
              const _tmp$6 = img.data;
              const _tmp$7 = (Math.imul((Math.imul(y, w) | 0) + x_out | 0, ch) | 0) + c | 0;
              const _tmp$8 = _tmp$5 - (_tmp$7 >>> 0 < _tmp$6.length ? _tmp$6[_tmp$7] : $oob()) | 0;
              const _tmp$9 = img.data;
              const _tmp$10 = (Math.imul((Math.imul(y, w) | 0) + x_in | 0, ch) | 0) + c | 0;
              sum = _tmp$8 + (_tmp$10 >>> 0 < _tmp$9.length ? _tmp$9[_tmp$10] : $oob()) | 0;
              _tmp$4 = x + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          _tmp$2 = c + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp = y + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const out = _M0MPC15array5Array4makeGyE(Math.imul(n, ch) | 0, 0);
  let _tmp$2 = 0;
  while (true) {
    const x = _tmp$2;
    if (x < w) {
      let _tmp$3 = 0;
      while (true) {
        const c = _tmp$3;
        if (c < color_ch) {
          let sum = 0;
          let _tmp$4 = 0;
          while (true) {
            const dy = _tmp$4;
            if (dy < win_size) {
              const y = _M0FP37walkzzz12image_2ecore5types12clamp__coord(dy - radius | 0, h);
              const _tmp$5 = sum;
              const _bind = (Math.imul((Math.imul(y, w) | 0) + x | 0, color_ch) | 0) + c | 0;
              if (_bind < 0 || _bind >= temp.len) {
                $panic();
              }
              sum = _tmp$5 + temp.buf[_bind] | 0;
              _tmp$4 = dy + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          let _tmp$5 = 0;
          while (true) {
            const y = _tmp$5;
            if (y < h) {
              const _bind = (Math.imul((Math.imul(y, w) | 0) + x | 0, ch) | 0) + c | 0;
              const _bind$2 = (sum / win_size | 0) & 255;
              if (_bind < 0 || _bind >= out.len) {
                $panic();
              }
              out.buf[_bind] = _bind$2;
              const y_out = _M0FP37walkzzz12image_2ecore5types12clamp__coord(y - radius | 0, h);
              const y_in = _M0FP37walkzzz12image_2ecore5types12clamp__coord((y + radius | 0) + 1 | 0, h);
              const _tmp$6 = sum;
              const _bind$3 = (Math.imul((Math.imul(y_out, w) | 0) + x | 0, color_ch) | 0) + c | 0;
              if (_bind$3 < 0 || _bind$3 >= temp.len) {
                $panic();
              }
              const _tmp$7 = _tmp$6 - temp.buf[_bind$3] | 0;
              const _bind$4 = (Math.imul((Math.imul(y_in, w) | 0) + x | 0, color_ch) | 0) + c | 0;
              if (_bind$4 < 0 || _bind$4 >= temp.len) {
                $panic();
              }
              sum = _tmp$7 + temp.buf[_bind$4] | 0;
              _tmp$5 = y + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          _tmp$3 = c + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp$2 = x + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (ch === 4) {
    let _tmp$3 = 0;
    while (true) {
      const i = _tmp$3;
      if (i < n) {
        const _bind = (Math.imul(i, ch) | 0) + 3 | 0;
        const _tmp$4 = img.data;
        const _tmp$5 = (Math.imul(i, ch) | 0) + 3 | 0;
        const _bind$2 = _tmp$5 >>> 0 < _tmp$4.length ? _tmp$4[_tmp$5] : $oob();
        if (_bind < 0 || _bind >= out.len) {
          $panic();
        }
        out.buf[_bind] = _bind$2;
        _tmp$3 = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  return new _M0DTPC16result6ResultGRP37walkzzz12image_2ecore5types5ImageRP37walkzzz12image_2ecore5types9LoadErrorE2Ok(new _M0TP37walkzzz12image_2ecore5types5Image(w, h, ch, _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(out.buf, 0, out.len))));
}
function _M0FP37walkzzz11image_2embt10playground10hex__value(c) {
  return c >= 48 && c <= 57 ? c - 48 | 0 : c >= 97 && c <= 102 ? (c - 97 | 0) + 10 | 0 : c >= 65 && c <= 70 ? (c - 65 | 0) + 10 | 0 : 0;
}
function _M0FP37walkzzz11image_2embt10playground14bytes__to__hex(data) {
  const out = _M0MPB13StringBuilder21StringBuilder_2einner(8);
  const _bind = data.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      const value = i >>> 0 < data.length ? data[i] : $oob();
      const _bind$2 = value >> 4 & 15;
      if (_bind$2 < 0 || _bind$2 >= _M0FP37walkzzz11image_2embt10playground10hex__chars.len) {
        $panic();
      }
      _M0IPB13StringBuilderPB6Logger11write__char(out, _M0FP37walkzzz11image_2embt10playground10hex__chars.buf[_bind$2]);
      const _bind$3 = value & 15;
      if (_bind$3 < 0 || _bind$3 >= _M0FP37walkzzz11image_2embt10playground10hex__chars.len) {
        $panic();
      }
      _M0IPB13StringBuilderPB6Logger11write__char(out, _M0FP37walkzzz11image_2embt10playground10hex__chars.buf[_bind$3]);
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return out.val;
}
function _M0FP37walkzzz11image_2embt10playground14hex__to__bytes(hex) {
  const chars = _M0MPC16string6String9to__array(hex);
  const count = chars.len / 2 | 0;
  const data = _M0MPC15array5Array4makeGyE(count, 0);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < count) {
      const _bind = Math.imul(i, 2) | 0;
      if (_bind < 0 || _bind >= chars.len) {
        $panic();
      }
      const hi = _M0FP37walkzzz11image_2embt10playground10hex__value(chars.buf[_bind]);
      const _bind$2 = (Math.imul(i, 2) | 0) + 1 | 0;
      if (_bind$2 < 0 || _bind$2 >= chars.len) {
        $panic();
      }
      const lo = _M0FP37walkzzz11image_2embt10playground10hex__value(chars.buf[_bind$2]);
      const _bind$3 = (hi << 4 | lo) & 255;
      if (i < 0 || i >= data.len) {
        $panic();
      }
      data.buf[i] = _bind$3;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return _M0MPC15bytes5Bytes11from__array(new _M0TPB9ArrayViewGyE(data.buf, 0, data.len));
}
function _M0FP37walkzzz11image_2embt10playground12img__version() {
  return "0.1.27";
}
function _M0FP37walkzzz11image_2embt10playground17img__qr__png__hex(text, module_px, quiet_zone) {
  const payload = _M0FPC28encoding4utf814encode_2einner(new _M0TPC16string10StringView(text, 0, text.length), false);
  if (payload.length === 0 || !_M0FP37walkzzz12image_2ecore7testgen8qr__fits(payload)) {
    return "";
  }
  const qz = quiet_zone < 4 ? 4 : quiet_zone;
  const image = _M0FP37walkzzz12image_2ecore7testgen18render__qr_2einner(payload, module_px, qz);
  return _M0FP37walkzzz11image_2embt10playground14bytes__to__hex(_M0FP37walkzzz13image_2ecodec3lib11encode__png(image));
}
function _M0FP37walkzzz11image_2embt10playground19img__qr__max__bytes() {
  return _M0FP37walkzzz12image_2ecore7testgen14qr__max__bytes();
}
function _M0FP37walkzzz11image_2embt10playground25img__qr__filter__png__hex(text, brightness, blur_radius) {
  let _try_err;
  _L: {
    const payload = _M0FPC28encoding4utf814encode_2einner(new _M0TPC16string10StringView(text, 0, text.length), false);
    if (payload.length === 0 || !_M0FP37walkzzz12image_2ecore7testgen8qr__fits(payload)) {
      return "";
    } else {
      const image = _M0FP37walkzzz12image_2ecore7testgen18render__qr_2einner(payload, 6, 4);
      const _bind = _M0FP37walkzzz15image_2eprocess5color18adjust__brightness(image, brightness);
      let bright;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        bright = _ok._0;
      } else {
        const _err = _bind;
        _try_err = _err._0;
        break _L;
      }
      const _bind$2 = _M0FP37walkzzz15image_2eprocess6filter9box__blur(bright, blur_radius);
      let filtered;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        filtered = _ok._0;
      } else {
        const _err = _bind$2;
        _try_err = _err._0;
        break _L;
      }
      return _M0FP37walkzzz11image_2embt10playground14bytes__to__hex(_M0FP37walkzzz13image_2ecodec3lib11encode__png(filtered));
    }
  }
  return "";
}
function _M0FP37walkzzz11image_2embt10playground17img__png__summary(png_hex) {
  if (png_hex.length === 0) {
    return "";
  }
  let _try_err;
  _L: {
    const _bind = _M0FP37walkzzz13image_2ecodec3lib19get__image__summary(_M0FP37walkzzz11image_2embt10playground14hex__to__bytes(png_hex));
    if (_bind.$tag === 1) {
      const _ok = _bind;
      return _ok._0;
    } else {
      const _err = _bind;
      _try_err = _err._0;
      break _L;
    }
  }
  return "";
}
export { _M0FP37walkzzz11image_2embt10playground12img__version as img_version, _M0FP37walkzzz11image_2embt10playground17img__qr__png__hex as img_qr_png_hex, _M0FP37walkzzz11image_2embt10playground19img__qr__max__bytes as img_qr_max_bytes, _M0FP37walkzzz11image_2embt10playground25img__qr__filter__png__hex as img_qr_filter_png_hex, _M0FP37walkzzz11image_2embt10playground17img__png__summary as img_png_summary }
