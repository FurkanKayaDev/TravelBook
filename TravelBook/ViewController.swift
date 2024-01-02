//
//  ViewController.swift
//  TravelBook
//
//  Created by Furkan Kaya on 2.01.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        //Best seçeneğiyle olabilecek en doğru location bilgisi alınıyor
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //Location bilgisi için izin isteme
        locationManager.requestWhenInUseAuthorization()
        //location bilgisini almaya başlıyoruz
        locationManager.startUpdatingLocation()
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        //onpress'in çalışma süresi
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            saveButton.isHidden = true
            //CoreDatayı tanımlama
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            //CoreData içindeki Places verilerini getir
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            //idString ile eşleşen veriyi getir
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        //Pin'in koordinatlarını ver
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        //Lokasyon almayı durdur
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        //Pini göster
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                    }
                                }
                                
                            }
                        }
                    }
                }
            } catch {
                
            }
            
        } else {
            saveButton.isHidden = false
            nameText.text = ""
            commentText.text = ""
        }
    }
    
    //parantez içindeki kısmın yazılma sebebi gestureRecognizer parametrelerine erişebilmek
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            // basılı tutulan yerin bilgilerini alır
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            choosenLatitude = touchedCoordinates.latitude
            choosenLongitude = touchedCoordinates.longitude
            
            // pin koyma ve isimlendirme işlemleri
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
            
        }
        
    }
    
    // güncellenen locationu verir
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            //konumumuzun haritada ki bilgisi
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            // zoom ayarı
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    //  Harita İşaretleme Görünümü Ayarları
    // Bu fonksiyon, harita üzerindeki her bir işaretleme için özel görünümü yapılandırır.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
         
         // Eğer işaretleme kullanıcının konumu ise, varsayılan görünümü kullan
         if annotation is MKUserLocation {
             return nil
         }
         
         let reuseId = "myAnnotation"
         var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
         
         // Eğer daha önce oluşturulmuş bir işaretleme görünümü yoksa, yeni bir tane oluştur
         if pinView == nil {
             pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
             pinView?.canShowCallout = true
             pinView?.tintColor = UIColor.black
             
             // İşaretleme üzerine tıklanınca gösterilecek sağ üst köşedeki detay butonu
             let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
             pinView?.rightCalloutAccessoryView = button
             
         } else {
             // Daha önce oluşturulmuş bir işaretleme görünümü varsa, onu kullan
             pinView?.annotation = annotation
         }
         
         return pinView
     }

    
    // Harita İşaretleme Detayı Tıklanınca Çağrılan Fonksiyon
    // Bu fonksiyon, harita üzerindeki bir işaretleme detayına tıklandığında çağrılır.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // Eğer bir yer seçili ise
        if selectedTitle != "" {
            // İşaretleme konumunu elde etmek için CLLocation nesnesi oluştur
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            // Yer adlandırma işlemleri için CLGeocoder kullanarak ters jeokodlama yap
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                
                // Eğer yer adlandırma başarılı olduysa
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        
                        // MKPlacemark oluştur ve MKMapItem ile entegre et
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        // Yol tarifi modunu belirleyerek haritada aç
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
        }
    }

    
    
    // Kaydet Butonuna Tıklanınca Çağrılan Fonksiyon
    // Bu fonksiyon, yeni bir yer kaydedildiğinde çağrılır.
    @IBAction func saveButton(_ sender: Any) {
        
        // Uygulama delegesini elde et
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Yeni bir Place (yer) nesnesi oluştur
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        // Yer bilgilerini belirlenen anahtarlar aracılığıyla Core Data'ya kaydet
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        // Core Data'ya kaydetme işlemi
        do {
            try context.save()
            print("Success") // Başarıyla kaydedildiğinde konsola bilgi yazdır
        } catch {
            print("Error") // Hata durumunda konsola hata mesajını yazdır
        }
        
        // Yeni bir yer eklendiğinde "newPlace" adlı notifikasyonu gönder
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        
        // Önceki sayfaya geri dönme işlemi
        navigationController?.popViewController(animated: true)
    }

}
