//
//  ViewController.swift
//  DragDropTest
//
//  Created by James Beattie on 07/11/2017.
//  Copyright © 2017 James Beattie. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController {
    
    var data = [[String]]()
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        data = [["1","2","3"],["4","5","6"]]
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.dropDelegate = self
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func randomColour() -> UIColor {
        let randomRed:CGFloat = CGFloat(arc4random_uniform(256))
        let randomGreen:CGFloat = CGFloat(arc4random_uniform(256))
        let randomBlue:CGFloat = CGFloat(arc4random_uniform(256))
        return UIColor(red: randomRed/255, green: randomGreen/255, blue: randomBlue/255, alpha: 1.0)
    }
    
    func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        let number = self.data[indexPath.section][indexPath.row]
        let data = number.data(using: .utf8)
        let itemProvider = NSItemProvider()
        itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypePlainText as String, visibility: .ownProcess) { (completion) -> Progress? in
            completion(data, nil)
            return nil
        }
        
        return [UIDragItem(itemProvider: itemProvider)]
    }
    
    func moveItem(from oldIndexPath: IndexPath, to newIndexPath: IndexPath) {
        let item = data[oldIndexPath.section].remove(at: oldIndexPath.row)
        data[newIndexPath.section].insert(item, at: newIndexPath.row)
    }
    
    func indexPath(for item: String) -> IndexPath? {
        var oldIndexPath: IndexPath?
        for (outerIndex, arr) in data.enumerated() {
            for (innerIndex, elem) in arr.enumerated() {
                if elem == item {
                    oldIndexPath = IndexPath(row: innerIndex, section: outerIndex)
                }
            }
        }
        return oldIndexPath
    }

}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.section][indexPath.row]
        cell.backgroundColor = randomColour()
        return cell
    }
}

extension ViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        coordinator.session.loadObjects(ofClass: String.self) { (items) in
            let stringItems = items
            var indexPaths = [(IndexPath, IndexPath)]()
            for (index, item) in stringItems.enumerated() {
                
                guard let oldIndexPath = self.indexPath(for: item) else { continue }
                let newIndexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
                indexPaths.append((oldIndexPath, newIndexPath))
            }
            let sortedPaths = indexPaths.sorted(by: { $0.0.row > $1.0.row })
            
            for oldAndNew in sortedPaths {
                self.moveItem(from: oldAndNew.0, to: oldAndNew.1)
            }
            tableView.beginUpdates()
            for oldAndNew in sortedPaths {
                tableView.moveRow(at: oldAndNew.0, to: oldAndNew.1)
            }
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if tableView.hasActiveDrag {
//            if session.items.count > 1 {
//                return UITableViewDropProposal(operation: .cancel)
//            } else {
                return UITableViewDropProposal(operation: .move)
//            }
        } else {
            return UITableViewDropProposal(operation: .copy)
        }
    }
    
}

extension ViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return dragItems(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(for: indexPath)
    }
}

