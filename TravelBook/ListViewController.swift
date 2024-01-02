//
//  ListViewController.swift
//  TravelBook
//
//  Created by Furkan Kaya on 2.01.2024.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var titleArray = [String]()
    var idArray = [UUID]()
    var chosenTitle = ""
    var chosenTitleId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))

        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
    }
    
    // View'ın Görüneceği Zaman Çağrılan Fonksiyon
    // Bu fonksiyon, ViewController'ın görüntülendiği zaman çağrılır ve veri güncellemelerini dinler.
    override func viewWillAppear(_ animated: Bool) {
        
        // NotificationCenter ile "newPlace" adlı notifikasyonu dinleyerek getData fonksiyonunu tetikle
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }

    
    // Veri Alımı İçin Fonksiyon
    // Bu fonksiyon, Core Data'dan veri alarak titleArray ve idArray dizilerini günceller.
    @objc func getData() {
        
        // Uygulama delegesini elde et
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Core Data'dan "Places" entity'si için sorgu oluştur
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        // Sorguyu gerçekleştir
        do {
            let results = try context.fetch(request)
            
            // Eğer sonuçlar bulunduysa
            if results.count > 0 {
                
                // titleArray ve idArray dizilerini temizle
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                
                // Her bir sonuç için
                for result in results as! [NSManagedObject] {
                    
                    // "title" özelliğini elde et ve titleArray'e ekle
                    if let title = result.value(forKey: "title") as? String {
                        self.titleArray.append(title)
                    }
                    
                    // "id" özelliğini elde et ve idArray'e ekle
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    
                    // TableView'ı güncelle
                    tableView.reloadData()
                }
            }
        } catch {
            // Hata durumunda bir şey yapma
        }
    }

    
    @objc func addButtonClicked() {
        chosenTitle = "" 
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenTitleId = idArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    // TableView Düzenleme Stili Fonksiyonu
    // Bu fonksiyon, TableView hücresinin düzenleme stiline göre çağrılır (örneğin, bir hücre silindiğinde).
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // Eğer düzenleme stili "sil" ise
        if editingStyle == .delete {
            
            // Uygulama delegesini elde et
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            // Silinecek yerin UUID'sini elde et
            let stringId = idArray[indexPath.row].uuidString
            
            // Core Data'dan silme işlemi için sorgu oluştur
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            fetchRequest.predicate = NSPredicate(format: "id = %@", stringId)
            fetchRequest.returnsObjectsAsFaults = false
            
            // Sorguyu gerçekleştir
            do {
                let results = try context.fetch(fetchRequest)
                
                // Eğer sonuçlar bulunduysa
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        // Yer kaydını Core Data'dan sil
                        context.delete(result)
                        
                        // TableView'daki veri dizilerinden de ilgili öğeyi kaldır
                        titleArray.remove(at: indexPath.row)
                        idArray.remove(at: indexPath.row)
                        
                        // TableView'ı güncelle
                        self.tableView.reloadData()
                        
                        // Core Data'ya yapılan değişiklikleri kaydet
                        do {
                            try context.save()
                        } catch {
                            // Hata durumunda bir şey yapma
                        }
                    }
                }
            } catch {
                // Hata durumunda bir şey yapma
            }
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedTitleID = chosenTitleId
        }
    }
}
