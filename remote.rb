require 'watir-webdriver'
require 'nokogiri'
require 'pry'
require 'json'

def trans_array (array, hash, date_arr, index)
  array.each do |element| 
    selector = element.css('td font tt')
    if selector[4].text.strip.gsub(/\"/,'').match(/^\d{2}\/\d{2}\/\d{2}\s*/)
      date   = selector[4].text.strip.gsub(/\"/,'')
      post_d = Date.strptime(date, DATE_DMY).to_json
    else 
      date   = date_arr[index]
      post_d = Date.strptime(date, DATE_DMY).to_json
      index += 1
    end

    if selector.size    == 7
      comission_element = selector[5].text.strip.gsub(/\"/,'')
      total_element     = selector[6].text.strip.gsub(/\"/,'')
    elsif selector.size == 6
      comission_element = selector[4].text.strip.gsub(/\"/,'')
      total_element     = selector[5].text.strip.gsub(/\"/,'')
    end

    hash.push(
      trans_date:   Date.strptime(selector[0].text.strip.gsub(/\"/,''), DATE_DMY).to_json,
      details:      selector[1].text.strip.gsub(/\"/,''),
      amount:       selector[2].text.strip.gsub(/\"/,''),
      currency:     selector[3].text.strip.gsub(/\"/,''),
      post_date:    post_d,
      comission:    comission_element,
      total_amount: total_element
    )
  end
  hash
end

def other_trans_array (array, hash)
  array.each do |element|
    selector = element.css('td font tt')
    units    = selector
    tds      = units.map { |td| td.text.strip.gsub(/\"/,'') }
    hash.push(
      post_date:      Date.strptime(tds[0], DATE_DMY).to_json,
      trans_date:     Date.strptime(tds[1], DATE_DMY).to_json,
      details:        tds[2],
      trans_amount:   tds[3],
      trans_currency: tds[4],
      acc_amount:     tds[5],
      acc_currency:   tds[6]
      )
  end
  hash
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
  page.css('tbody tr').each do |element|
    selector = element.css('td font tt')
    if element.text.strip.match(/^\d{2}\/\d{2}\/\d{2}\s*[A-z]\S*/)
      arr_1 << element
    elsif element.text.strip.match(/^\d{2}\/\d{2}\/\d{2}\s{1,5}\d{2}\/\d{2}\/\d{2}/)
      arr_2 << element
    elsif element.text.strip.match(/^\d{2}\/\d{2}\/\d{2}$/)
      arr_3 << selector.text.strip.gsub(/\"/,'')
    end   
  end 
end

DATE_DMY    = '%d/%m/%y'
data_arr    = []
itter       = 1
index       = 0
post_d      = nil
day         = "owwb-ws-calendar-current-month-day"
from_date   = "USER_PROPERTY_DATE_FROM_DATEPICKER_SWITCH"
nav_prev    = "owwb-ws-calendar-nav-prev"
trans_entry = "owwb_cs_submit_emulator form_owwb_ws_entryAccountDoing-"
confirm     = "owwb-cs-default-button-bg"
back_main   = "form_GO_TO_PARENT_SECTION"

browser = Watir::Browser.new(:firefox)
browser.goto 'https://wb.micb.md/frontend/auth/userlogin?execution=e2s1'

until browser.link(:name => "main_menu_CP_HISTORY").exist?
  print "Login: "
  login    = gets.chomp
  print "Password "
  password = gets.chomp
  browser.text_field(:name => "Login").when_present.set(login)
  browser.text_field(:name => "password").when_present.set(password)
  browser.link(:class => "owwb-cs-default-button").click
end

browser.link(:class => "owwb-cs-default-button").wait_while_present

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
  2.times do 
    browser.link(:class => nav_prev).wait_until_present
    browser.link(:class => nav_prev).click
  end
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
  browser.link(:class => back_main).click
  browser.link(:class => back_main).wait_while_present
end

puts JSON.pretty_generate(data_arr)
binding.pry

