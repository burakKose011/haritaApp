//
//  haritalarViewController.swift
//  haritalarUygulamasi2
//
//  Created by macbook on 11.02.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class haritalarViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var notTextField: UITextField!
    @IBOutlet weak var kaydetBtn: UIButton!
    
    
    var locationManager = CLLocationManager()  // canlı konum yöneticisi
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""  // table view de kayıtlı konumu buraya aktarıp gösterecez
    var secilenId : UUID? //  table view de kayıtlı konumu buraya aktarıp gösterecez
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self  // bunu kullanabilmek içim class a CLLocationManagerDelegate eklemeliyiz
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // alınan konum özelliği en iyi mesafeyi seçtik
        locationManager.requestWhenInUseAuthorization() // uygulama kullanılırken konum almaya izin veriyor uygulama güvenlik açısından
        locationManager.startUpdatingLocation()  // konumu günceller  // burada infoya gidip + ya basınca private kısmından Location When In Use Usage i seçip kullanıcıya bir mesaj gönderiyoruz
        
        
        
        
        //   ANNOTATİON (haritada işaret bırakma kırmızı konum işareti)   //
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer: ))) // jest algılayıcı long yani uzun süre tıklandığında seçilebilir
        
        gestureRecognizer.minimumPressDuration = 3  // 3 saniye basılı kalınırsa konum işaretini koyar
        mapView.addGestureRecognizer(gestureRecognizer)
        
        /////////////////////////////////////////////////////////////////////////////
        
        kaydetBtn.layer.cornerRadius = 10
        
        
        ///////////////////// VERİ AKTARMAK ////////////////////
        if secilenIsim != "" {
            // core data dan verileri çek
            if let uuidString1 = secilenId?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString1)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            
                            if let isim = sonuc.value(forKey: "isim") as? String {
                                annotationTitle = isim
                                
                                if let not = sonuc.value(forKey: "not") as? String {
                                    annotationSubtitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            
                                             let annotation = MKPointAnnotation()
                                             annotation.title = annotationTitle
                                             annotation.subtitle = annotationSubtitle
                                             let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                             annotation.coordinate = coordinate
                                             
                                             mapView.addAnnotation(annotation)
                                             isimTextField.text = annotationTitle
                                             notTextField.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation() //harita almanyada olsa bile table view de seçili konuma tıklayınca direk orsı açılır
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                             
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } catch {
                    print("hata")
                }
                
                
            } else {
                // yeni veri eklemeye geldi
            }
            //////////////////////////////////////////////////////
            
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if secilenIsim != "" {
            
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
                
                if let placemarks = placemarkDizisi {
                    
                    if placemarks.count > 0 {
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                        
                  }
               }
            }
        }
    }
    
    
    ////////////////////////////// ANNOTATİON (tıkladığımız yere konum işareti koyma) /////////////////////////
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text    // konum başlığı tıklandığında bilgi verir
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
        }
    }
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //  print(locations[0].coordinate.latitude)  // bize kordinat enlem ve boylam gösteriyor
        //  print(locations[0].coordinate.longitude)   // bunlarla kullanıcının konumlarını alıyoruz
        
        /////////////////// DÜZELTMELER //////////////////////
        if secilenIsim == "" {
            
            //////////////////////////////////////////////////////  HARİTAYI OYNATMAK ///////////////////////////////////////////////////////
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)   // haritanın zoomunu ayarladık 0.1 demek çok yakın bir değer
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            
        }
        ///////////////////////////////////////////////////////
    }
    
   
    
    ////////////////////////////// KONUMU KAYDETMEK (core data ile) ////////////////////////////////
    @IBAction func kaydetButonu(_ sender: Any) {
        
            // burada coredata kullanacağımız için import coredata kütüphanesini kullanacaz
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
            
            yeniYer.setValue(isimTextField.text, forKey: "isim")
            yeniYer.setValue(notTextField.text, forKey: "not")
            yeniYer.setValue(secilenLatitude, forKey: "latitude")
            yeniYer.setValue(secilenLongitude, forKey: "longitude")
            yeniYer.setValue(UUID(), forKey: "id")
            
            do {
                try context.save()
                print("kayıt edildi")
            } catch {
                print("hata")
            }
        
       ////////////// ÖZEL ANNOTATİON (konumun yanina i adında bir bilgi butonu koyar /////////////
       NotificationCenter.default.post(name: NSNotification.Name("yeniYerOluşturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
        
        
        
            
        }
       /////////////////////////////////////////////////////////////////////////////////////////////////
    
}




















//  Main içinde + ya tıklayıp Map Kit View i ekleyecez


//konumu kaydetmek istersek core data kullanacaz ve bir buton koyacaz
/* konumu kaydetmek için
 1. haritalarUygulamasi'na gir
 2. add entity e tıkla
 3. entity kısmının ismini yer olarak koyduk ve kaydetmek istediklerimizi attribute ye koyduk
*/
