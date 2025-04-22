//
//  File.swift
//  
//
//  Created by Aleksandras Gaidamausas on 15/08/2024.
//

import Foundation

let xml = """
<gpx>
<metadata>
 <time>2019-02-14T07:08:19Z</time>
</metadata>
<trk>
 <name>Morning Run</name>
 <trkseg>
  <trkpt lat="53.2693780" lon="-2.3478250">
   <ele>64.7</ele>
   <time>2019-02-14T07:08:19Z</time>
   <extensions>
    <gpxtpx:TrackPointExtension>
     <gpxtpx:hr>123</gpxtpx:hr>
     <gpxtpx:cad>94</gpxtpx:cad>
    </gpxtpx:TrackPointExtension>
   </extensions>
  </trkpt>
  <trkpt lat="53.2693780" lon="-2.3478250">
   <ele>64.7</ele>
   <time>2019-02-14T07:08:21Z</time>
   <extensions>
    <gpxtpx:TrackPointExtension>
     <gpxtpx:hr>123</gpxtpx:hr>
     <gpxtpx:cad>94</gpxtpx:cad>
    </gpxtpx:TrackPointExtension>
   </extensions>
  </trkpt>
 </trkseg>
</trk>
</gpx>
"""

//<key>UTImportedTypeDeclarations</key>
//  <array>
//    <dict>
//      <key>UTTypeIdentifier</key>
//      <string>com.testapp.gpx</string>
//      <key>UTTypeDescription</key>
//      <string>GPS Exchange Format (GPX)</string>
//      <key>UTTypeConformsTo</key>
//      <array>
//        <string>public.xml</string>
//      </array>
//      <key>UTTypeTagSpecification</key>
//      <dict>
//        <key>public.filename-extension</key>
//        <array>
//          <string>gpx</string>
//        </array>
//        <key>public.mime-type</key>
//        <string>application/gpx+xml</string>
//      </dict>
//    </dict>
//  </array>


//<key>CFBundleDocumentTypes</key>
//  <array>
//    <dict>
//      <key>CFBundleTypeIconFiles</key>
//      <array/>
//      <key>CFBundleTypeName</key>
//      <string>GPS Exchange Format (GPX)</string>
//      <key>CFBundleTypeRole</key>
//      <string>Editor</string>
//      <key>LSHandlerRank</key>
//      <string>Owner</string>
//      <key>LSItemContentTypes</key>
//      <array>
//        <string>com.testapp.gpx</string>
//      </array>
//    </dict>
//  </array>


//func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//   if url.pathExtension == "gpx" {
//       // handle GPX url
//   }
//   return true
// }
