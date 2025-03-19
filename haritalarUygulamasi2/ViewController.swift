//
//  ViewController.swift
//  haritalarUygulamasi2
//
//  Created by macbook on 11.02.2024.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    
    var secilenYerIsmi = ""
    var secilenYerId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // burada table view e sağ üste + işareti koyduk
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addItem))
        
        
        tableView.delegate = self      // table view için buraya bunları yazmalıyız
        tableView.dataSource = self
        
        tableView.layer.cornerRadius = 20
        
        veriAl()
    
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(veriAl), name: NSNotification.Name("yeniYerOluşturuldu"), object: nil)
    }
    
    
    
    ////////////////////////// VERİLERİ ÇEKMEK ////////////////////////////
    // core dataya kaydettiğimiz konumu table view de çekmek
    @objc func veriAl() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        request.returnsObjectsAsFaults = false
        
        do {
            let sonuclar = try context.fetch(request)
            
            if sonuclar.count > 0 {
                
                isimDizisi.removeAll(keepingCapacity: false)
                idDizisi.removeAll(keepingCapacity: false)
                
                for sonuc in sonuclar as! [NSManagedObject] {
                    
                    if let isim = sonuc.value(forKey: "isim") as? String {
                        isimDizisi.append(isim)
                    }
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                }
                tableView.reloadData()
            }
            
        } catch {
            print("hata")
        }
        
    }
    ///////////////////////////////////////////////////////////////////////
    
    
    
    @objc func addItem() {
        secilenYerIsmi = ""  // burayı boş atıyoruz ki yeni veri eklemek istediğimizi anlasın diye
        performSegue(withIdentifier: "aktarim1", sender: nil)
    }
    
    
    // numberOfRowsInSection -> kaç tane row olacak yani kaç tane alt alta bölüm
    // cellForRow atIndexPath -> hücrenin içerisinde neler gösterilecek
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return isimDizisi.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = UITableViewCell()
            cell.textLabel?.text = isimDizisi[indexPath.row]
            return cell
        }
    
    
    ///////////////////////////// VERİLERİ AKTARMAK /////////////////////////////////
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        secilenYerIsmi = isimDizisi[indexPath.row]
        secilenYerId = idDizisi[indexPath.row]
        performSegue(withIdentifier: "aktarim1", sender: nil)
    }
    
    // veri aktarımı
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        if segue.identifier == "aktarim1" {
            let destinationVC = segue.destination as! haritalarViewController
            destinationVC.secilenIsim = secilenYerIsmi
            destinationVC.secilenId = secilenYerId
        }
    }
/////////////////////////////////////////////////////////////////////////////////////

}

