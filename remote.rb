require 'watir-webdriver'
require 'nokogiri'
require 'pry'
require 'json'

browser = Watir::Browser.new
browser.goto('file:///home/zik/ruby/web.html')

page = Nokogiri::HTML(browser.html)

data_arr = []

itter = 1
index = 0
post_d = nil

page.css('.owwb-cs-slide-list-account-item').each do |i|
  account  = i.css('.contract-number').text
  balance  = i.css('.owwb-cs-slide-list-amount-value').text.to_f
  currency = i.css('.owwb-cs-slide-list-amount-currency').text

  pag = []
  i.css('li').each do |li|  
    li.children.children.children.each{ |i| pag << i.text.strip.gsub(/\s{2,100}/, '') } 
  end 

  pag = pag.select{ |i| i =~ /[a-z, 1-8]/ }
  nature = pag[pag.index("Produsul")+1]
  adress = 'file:///home/zik/ruby/trans_list_' + itter.to_s + '.html'
  browser.goto(adress)
  itter += 1
  transactions_page = Nokogiri::HTML(browser.html)

  tr_arr_1 = []
  tr_arr_2 = []
  tr_arr_3 = []

  transactions_page.css('tbody').each do |tbody|
    tbody.children.each do |tr|  
      if tr.text.strip.match(/^\d{2}\/\d{2}\/\d{2}\s*[a-zA-Z]\S*/)
        tr_arr_1 << tr
      elsif tr.text.strip.match(/^\d{2}\/\d{2}\/\d{2}\s{1,5}\d{2}\/\d{2}\/\d{2}/)
        tr_arr_2 << tr
      elsif tr.text.strip.match(/^\d{2}\/\d{2}\/\d{2}$/)
        tr_arr_3 << tr.children.children.children.text.strip.gsub(/\"/,'')
      end  
    end  
  end

  trans_hash_1 = []
  trans_hash_2 = []

  tr_arr_1.each{ |element|
    
    if element.children.children.children[4].text.strip.gsub(/\"/,'').match(/^\d{2}\/\d{2}\/\d{2}\s*/)
      post_d = Date.parse(element.children.children.children[4].text.strip.gsub(/\"/,'').split('/').reverse.join) 
    else 
      post_d = tr_arr_3[index].split('/').reverse.join
      post_d = Date.parse(post_d)
      index += 1
    end 

    trans_hash_1.push(
      trans_date: Date.parse(element.children.children.children[0].text.strip.gsub(/\"/,'').split('/').reverse.join),
      details:    element.children.children.children[1].text.strip.gsub(/\"/,''),
      amount:     element.children.children.children[2].text.strip.gsub(/\"/,''),
      currency:   element.children.children.children[3].text.strip.gsub(/\"/,''),
      post_date:  post_d,
      comission:  element.children.children.children[5].text.strip.gsub(/\"/,''),
      #total:      element.children.children.children[6].text.strip.gsub(/\"/,'')
    )
  }
  tr_arr_2.each{ |element|
    trans_hash_2.push(
      post_date:      Date.parse(element.children.children.children[0].text.strip.gsub(/\"/,'').split('/').reverse.join),
      trans_date:     Date.parse(element.children.children.children[1].text.strip.gsub(/\"/,'').split('/').reverse.join),
      details:        element.children.children.children[2].text.strip.gsub(/\"/,''),
      trans_amount:   element.children.children.children[3].text.strip.gsub(/\"/,''),
      trans_currency: element.children.children.children[4].text.strip.gsub(/\"/,''),
      acc_amount:     element.children.children.children[5].text.strip.gsub(/\"/,''),
      acc_currency:   element.children.children.children[6].text.strip.gsub(/\"/,'')
    )
  }

  data_arr.push(  
    name:               account,
    balance:            balance,
    currency:           currency,
    nature:             nature,
    transactions:       trans_hash_1,
    other_transactions: trans_hash_2
  )
end

puts JSON.pretty_generate(data_arr)

binding.pry
