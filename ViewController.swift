import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var cToF: UISwitch!
    private let locationManager = CLLocationManager()
    private var weatherResponse: WeatherResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        locationManager.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        loadWeather(search: searchTextField.text)
        return true
    }
    
    @IBAction func onLocationTapped(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }
    
    @IBAction func onToggleSwitch(_ sender: UISwitch) {
        updateTemperatureLabel()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("No location available")
            return
        }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let query = "\(latitude),\(longitude)"
        loadWeather(search: query)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    private func loadWeather(search: String?) {
        guard let search = search, let url = getURL(query: search) else {
            print("Invalid search query or URL.")
            return
        }
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { [weak self] data, response, error in
            guard error == nil, let data = data else {
                print("Error in network call or no data.")
                return
            }
            
            if let weatherResponse = self?.parseJson(data: data) {
                self?.weatherResponse = weatherResponse
                DispatchQueue.main.async {
                    self?.updateUI(with: weatherResponse)
                    self?.updateTemperatureLabel()
                }
            }
        }
        dataTask.resume()
    }
    
    private func getURL(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "00f7056e7d704c2a994161104241703"
        let units = cToF.isOn ? "f" : "c"
        guard let urlString = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)&units=\(units)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        
        return URL(string: urlString)
    }
    
    private func parseJson(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Error decoding: \(error)")
            return nil
        }
    }
    
    private func updateUI(with weatherResponse: WeatherResponse) {
        self.locationLabel.text = weatherResponse.location.name
        
        let weatherCode = weatherResponse.current.condition.code
        var symbolConfiguration: UIImage.SymbolConfiguration?
        
        switch weatherCode {
            case 1000: // Sunny
                symbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [.systemYellow])
                weatherConditionImage.image = UIImage(systemName: "sun.max.fill", withConfiguration: symbolConfiguration)
                
            case 1003, 1006: // Partly cloudy, Cloudy
                symbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [.systemGray3, .yellow])
                weatherConditionImage.image = UIImage(systemName: "cloud.sun.fill", withConfiguration: symbolConfiguration)
                
            case 1183, 1189: // Light rain, Moderate rain
                symbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [.systemBlue])
                weatherConditionImage.image = UIImage(systemName: "cloud.rain.fill", withConfiguration: symbolConfiguration)
                
            case 1225: // Snow
                symbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [.systemBlue, .white])
                weatherConditionImage.image = UIImage(systemName: "snow", withConfiguration: symbolConfiguration)
                
            // Additional cases
            case 1063, 1150, 1153: // Patchy rain nearby, Patchy light drizzle, Patchy light rain
                symbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [.systemBlue])
                weatherConditionImage.image = UIImage(systemName: "cloud.drizzle.fill", withConfiguration: symbolConfiguration)
                
            case 1066, 1210, 1213: // Patchy snow possible, Patchy light snow, Patchy moderate snow
                symbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [.systemBlue, .white])
                weatherConditionImage.image = UIImage(systemName: "cloud.snow.fill", withConfiguration: symbolConfiguration)
                
            case 1069, 1207, 1240: // Patchy sleet possible, Light freezing rain, Moderate or heavy freezing rain
                symbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [.systemBlue])
                weatherConditionImage.image = UIImage(systemName: "cloud.sleet.fill", withConfiguration: symbolConfiguration)
                
            default:
                // Default case for other weather codes
                weatherConditionImage.image = UIImage(systemName: "questionmark.circle")
                weatherConditionImage.preferredSymbolConfiguration = nil
        }
    }
    
    private func updateTemperatureLabel() {
        guard let weatherResponse = weatherResponse else { return }
        
        if cToF.isOn {
            temperatureLabel.text = "\(weatherResponse.current.temp_f)°F"
        } else {
            temperatureLabel.text = "\(weatherResponse.current.temp_c)°C"
        }
    }
    
    struct WeatherResponse: Decodable {
        let location: Location
        let current: Weather
    }
    
    struct Location: Decodable {
        let name: String
    }
    
    struct Weather: Decodable {
        let temp_c: Float
        let temp_f: Float
        let condition: WeatherCondition
    }
    
    struct WeatherCondition: Decodable {
        let text: String
        let code: Int
    }
}
