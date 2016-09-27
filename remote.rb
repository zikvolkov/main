require 'watir-webdriver'
require 'nokogiri'
require 'pry'
require 'json'

def trans_array (array, hash, date_arr, index)
  array.each do |element| 
    if element.css('td font tt')[4].text.strip.gsub(/\"/,'').match(/^\d{2}\/\d{2}\/\d{2}\s*/)
      post_d = Date.parse(element.css('td font tt')[4].text.strip.gsub(/\"/,'').split('/').reverse.join) 
    else 
      post_d = Date.parse(date_arr[index].split('/').reverse.join)
      index += 1
    end 

    hash.push(
      trans_date: Date.parse(element.css('td font tt')[0].text.strip.gsub(/\"/,'').split('/').reverse.join),
      details:    element.css('td font tt')[1].text.strip.gsub(/\"/,''),
      amount:     element.css('td font tt')[2].text.strip.gsub(/\"/,''),
      currency:   element.css('td font tt')[3].text.strip.gsub(/\"/,''),
      post_date:  post_d,
      comission:  element.css('td font tt')[5].text.strip.gsub(/\"/,''),
      #total:      element.css('td font tt')[6].text.strip.gsub(/\"/,'')
    )
  end
  return hash
end

def other_trans_array (array, hash)
  array.each do |element|
    units    = element.css('td font tt')
    tds      = units.map { |td| td.text.strip.gsub(/\"/,'') }
    date_tds = units.map { |td| td.text.strip.gsub(/\"/,'').split('/').reverse.join }
    hash.push(
      post_date:      Date.parse(date_tds[0]),
      trans_date:     Date.parse(date_tds[1]),
      details:        tds[2],
      trans_amount:   tds[3],
      trans_currency: tds[4],
      acc_amount:     tds[5],
      acc_currency:   tds[6]
      )
  end
  return hash
end

def data (array, item, elements_arr, transactions, other_transactions)
  array.push(  
    name:               item.css('.contract-number').text,
    balance:            item.css('.owwb-cs-slide-list-amount-value').text.to_f,
    currency:           item.css('.owwb-cs-slide-list-amount-currency').text,
    nature:             elements_arr[elements_arr.index("Produsul")+1],
    transactions:       transactions,
    other_transactions: other_transactions
  )
end

def trans_page (arr_1, arr_2, arr_3, page)
  page.css('tbody tr').each do |tr| 
    if tr.text.strip.match(/^\d{2}\/\d{2}\/\d{2}\s*[A-z]\S*/)
      arr_1 << tr
    elsif tr.text.strip.match(/^\d{2}\/\d{2}\/\d{2}\s{1,5}\d{2}\/\d{2}\/\d{2}/)
      arr_2 << tr
    elsif tr.text.strip.match(/^\d{2}\/\d{2}\/\d{2}$/)
      arr_3 << tr.css('td font tt').text.strip.gsub(/\"/,'')
    end   
  end 
end

data_arr = []
itter    = 1
index    = 0
post_d   = nil
login    = "#######"
password = "#######"


browser = Watir::Browser.new(:firefox)
browser.goto 'https://wb.micb.md/frontend/auth/userlogin?execution=e2s1'
browser.text_field(:name => "Login").set(login)
browser.text_field(:name => "password").set(password)
browser.a(:class => "owwb-cs-default-button").click

page = Nokogiri::HTML(browser.html)

page.css('.owwb-cs-slide-list-account-item').each do |item|
  elements_arr = []

  item.css('li').each do |li|  
    li.children.children.children.each { |i| elements_arr << i.text.strip.gsub(/\s{2,100}/, '') } 
  end 

  elements_arr = elements_arr.select { |i| i =~ /[a-z, 1-8]/ }
  
  adress = browser.link(:class => "owwb_cs_submit_emulator form_owwb_ws_entryAccountDoing-" + itter.to_s + "_1").click
  browser.goto(adress)
  browser.link(:id => "USER_PROPERTY_DATE_FROM_DATEPICKER_SWITCH").click
  2.times{ browser.link(:class => "owwb-ws-calendar-nav-prev").click }
  browser.link(:class => "owwb-ws-calendar-current-month-day").click
  browser.link(:class => "owwb-cs-default-button-bg").click
  
  itter += 1

  transactions_page = Nokogiri::HTML(browser.html)

  tr_arr_1       = []
  tr_arr_2       = []
  tr_arr_3       = []
  trans_hash_1   = []
  trans_hash_2   = []
  trans_page(tr_arr_1, tr_arr_2, tr_arr_3, transactions_page)
  transactions_1 = trans_array(tr_arr_1, trans_hash_1, tr_arr_3, index)
  transactions_2 = other_trans_array(tr_arr_2, trans_hash_2)
  data(data_arr, item, elements_arr, transactions_1, transactions_2)
end

puts JSON.pretty_generate(data_arr)
binding.pry

