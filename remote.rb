require 'watir-webdriver'
require 'nokogiri'
require 'pry'
require 'json'

def trans_array (array, hash, date_arr, index)
  array.each do |element| 
    if element.css('td font tt')[4].text.strip.gsub(/\"/,'').match(/^\d{2}\/\d{2}\/\d{2}\s*/)
      d = element.css('td font tt')[4].text.strip.gsub(/\"/,'')
      post_d = Date.strptime(d, '%d/%m/%y').to_json
    else 
      d = date_arr[index]
      post_d = Date.strptime(d, '%d/%m/%y').to_json
      index += 1
    end

    if element.css('td font tt').size == 7
      comission_element = element.css('td font tt')[5].text.strip.gsub(/\"/,'')
      total_element     = element.css('td font tt')[6].text.strip.gsub(/\"/,'')
    elsif element.css('td font tt').size == 6
      comission_element = element.css('td font tt')[4].text.strip.gsub(/\"/,'')
      total_element     = element.css('td font tt')[5].text.strip.gsub(/\"/,'')
    end

    hash.push(
      trans_date:   Date.strptime(element.css('td font tt')[0].text.strip.gsub(/\"/,''), '%d/%m/%y').to_json,
      details:      element.css('td font tt')[1].text.strip.gsub(/\"/,''),
      amount:       element.css('td font tt')[2].text.strip.gsub(/\"/,''),
      currency:     element.css('td font tt')[3].text.strip.gsub(/\"/,''),
      post_date:    post_d,
      comission:    comission_element,
      total_amount: total_element
    )
  end
  return hash
end

def other_trans_array (array, hash)
  array.each do |element|
    units    = element.css('td font tt')
    tds      = units.map { |td| td.text.strip.gsub(/\"/,'') }
    hash.push(
      post_date:      Date.strptime(tds[0], '%d/%m/%y').to_json,
      trans_date:     Date.strptime(tds[1], '%d/%m/%y').to_json,
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

data_arr    = []
itter       = 1
index       = 0
post_d      = nil
login       = "********"
password    = "********"
day         = "owwb-ws-calendar-current-month-day"
from_date   = "USER_PROPERTY_DATE_FROM_DATEPICKER_SWITCH"
nav_prev    = "owwb-ws-calendar-nav-prev"
trans_entry = "owwb_cs_submit_emulator form_owwb_ws_entryAccountDoing-"
confirm     = "owwb-cs-default-button-bg"
back_main   = "form_GO_TO_PARENT_SECTION"

browser = Watir::Browser.new(:firefox)
browser.goto 'https://wb.micb.md/frontend/auth/userlogin?execution=e2s1'
browser.text_field(:name => "Login").when_present.set(login)
browser.text_field(:name => "password").when_present.set(password)
browser.a(:class => "owwb-cs-default-button").click
browser.a(:class => "owwb-cs-default-button").wait_while_present

page = Nokogiri::HTML(browser.html)

page.css('.owwb-cs-slide-list-account-item').each do |item|
  elements_arr = []

  item.css('li').each do |li|  
    li.children.children.children.each { |i| elements_arr << i.text.strip.gsub(/\s{2,100}/, '') } 
  end 

  elements_arr = elements_arr.select { |i| i =~ /[a-z, 1-8]/ }
  
  browser.link(:class => trans_entry + itter.to_s + "_1").click
  browser.link(:class => trans_entry + itter.to_s + "_1").wait_while_present
  browser.link(:id => from_date).wait_until_present
  browser.link(:id => from_date).click
  2.times{ browser.link(:class => nav_prev).wait_until_present
    browser.link(:class => nav_prev).click }
  browser.link(:class => day).wait_until_present  
  browser.link(:class => day).click
  browser.link(:class => confirm).click
  browser.link(:class => confirm).wait_while_present

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

  browser.div(:class => "owwb-ls-overlay-close").click
  browser.a(:class => back_main).click
  browser.a(:class => back_main).wait_while_present
end

puts JSON.pretty_generate(data_arr)
binding.pry

