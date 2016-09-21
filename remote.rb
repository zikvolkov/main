require 'watir-webdriver'
require 'nokogiri'
require 'pry'
require 'json'

browser = Watir::Browser.new
browser.goto('file:///home/zik/ruby/web.html')

page = Nokogiri::HTML(browser.html)

data_arr = []


itter = 1

page.css('.owwb-cs-slide-list-account-item').each do |i|
    account  = i.css('.contract-number').text
    balance  = i.css('.owwb-cs-slide-list-amount-value').text
    currency = i.css('.owwb-cs-slide-list-amount-currency').text

    pag = []
    i.css('li').each{|li|  
        li.children.children.children.each{|i| pag << i.text.strip.gsub(/\s{2,100}/, '')   
        } 
    }  
    pag.select{|i| i =~ /[a-z, 1-8]/}
    
    nature   = pag[pag.index("Produsul")+1]
    

    adress   = 'file:///home/zik/ruby/trans_list_' + itter.to_s + '.html'

    browser.goto(adress)
    itter += 1
    transactions_page = Nokogiri::HTML(browser.html)
    
    tr_arr = []

    transactions_page.css('tbody').each{|tbody|
        tbody.children.each{|tr|  
            if tr.text.strip.match(/^\d{2}\/\d{2}\/\d{2}\s{1,6}/) then
                tr_arr << tr
            end  
        }  
    }

    trans_hash = []

    tr_arr.each{|element|
        trans_date = element.children.children.children[0].text.strip.gsub(/\"/,'')
        details    = element.children.children.children[1].text.strip.gsub(/\"/,'')
        suma       = element.children.children.children[2].text.strip.gsub(/\"/,'')
        curr       = element.children.children.children[3].text.strip.gsub(/\"/,'')
        date       = element.children.children.children[4].text.strip.gsub(/\"/,'')
        commision  = element.children.children.children[5].text.strip.gsub(/\"/,'')
        #total      = element.children.children.children[6].text.strip.gsub(/\"/,'')

        trans_hash.push(
            trans_date: trans_date,
            details:    details,
            suma:       suma,
            currency:   curr,
            date:       date,
            comission:  commision,
           #total:      total
           )
    }



    data_arr.push(  
        name:         account,
        balance:      balance,
        currency:     currency,
        nature:       nature,
        transactions: trans_hash
        )  
end

binding.pry
puts JSON.pretty_generate(data_arr)

