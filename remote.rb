require 'watir-webdriver'
require 'nokogiri'
require 'pry'

browser = Watir::Browser.new
browser.goto('file:///home/zik/ruby/web.html')

page = Nokogiri::HTML(browser.html)

data = []

page.css('.owwb-cs-slide-list-account-item').each do |i|
    account  = i.css('.contract-number').text
    balance  = i.css('.owwb-cs-slide-list-amount-value').text
    currency = i.css('.owwb-cs-slide-list-amount-currency').text
    #nature = 

data.push(  
    name:     account,
    balance:  balance,
    currency: currency
    #nature:   nature
)  
end  
binding.pry
