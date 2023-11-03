from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium import webdriver
from selenium.webdriver import FirefoxOptions
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
import os
import time
import pandas as pd
from concurrent.futures import ThreadPoolExecutor
from threading import Lock
import traceback
import re
import sys
from datetime import datetime

pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.expand_frame_repr', False)
pd.set_option('display.width', None)
pd.set_option('display.max_colwidth', None)

counter_lock = Lock()

def scrape(accr_code):
    global counter
 
    
    driver = None
    search_results_data = []
    transfer_history_data = []
    try:
        opts = FirefoxOptions()
        opts.add_argument("--headless")
        driver = webdriver.Firefox(options=opts)
        driver.get("https://www.rec-registry.gov.au/rec-registry/app/public/stc-register")

        # Making sure the search box is ready and visible
        search_box = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID, 'accreditationCode')))
        search_box.send_keys(accr_code, Keys.ENTER)
        #time.sleep(10)

        # Making sure the table is ready and visible
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, '//*[@id="search-ranges-results"]/tbody/tr')))
        s_rows = driver.find_elements(By.XPATH, '//*[@id="search-ranges-results"]/tbody/tr')

        # Check if large amount of data is returned
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, '//*[@id="search-ranges-results_info"]')))
        search_results_range = driver.find_element(By.XPATH, '//*[@id="search-ranges-results_info"]').text
        exceed_10_rows_flag = int(re.findall(r'\d+', search_results_range)[-1]) > 10

        if exceed_10_rows_flag:
            raise Exception('Large amount of data returned')

        for s_row in s_rows:
            s_cols = s_row.find_elements(By.TAG_NAME, 'td')
            s_cols_data = [ele.text for ele in s_cols]  
            search_results_data.append(s_cols_data)

            if s_cols_data == ['No data available in table']:
                raise Exception('Accreditation code not found')
                
            # Open the popup window
            link = s_cols[7].find_element(By.TAG_NAME, 'a')
            link.click()
            WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, '//*[@id="transfer-history-results"]/tbody/tr')))
            t_rows = driver.find_elements(By.XPATH, '//*[@id="transfer-history-results"]/tbody/tr')
            
            for t_row in t_rows:
                t_cols = t_row.find_elements(By.TAG_NAME, 'td')
                t_cols_data = [ele.text for ele in t_cols]
                if t_cols_data == ['No data available in table']:
                    t_cols_data.append("None")
                    t_cols_data.append("None")
                else:
                    t_cols_data.append(s_cols[7].text)
                    t_cols_data.append(s_cols[1].text)

                transfer_history_data.append(t_cols_data)

            # Close the popup windows (ready for the next s_row (search results row))
            # WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, '//*[@id="certificate-details-dialog"]')))
            # html = driver.find_element(By.XPATH, '//*[@id="certificate-details-dialog"]')
            # html.send_keys(Keys.ESCAPE)

    except Exception as e:
        if str(e) == 'Accreditation code not found':
            print(f"Accreditation code {accr_code} not found.")
            transfer_history_data.append(['None','None','None','None',accr_code])
            if driver:
                driver.quit()
        elif str(e) == 'Large amount of data returned':
            print(f"Accreditation code {accr_code} contains a large ammount of data.")
            transfer_history_data.append(['None','None','None','None',accr_code])
            if driver:
                driver.quit()
        else:
            print(f"An error occurred processing: {accr_code} in scrape: {e}")
            traceback.print_exc()
            if driver:
                driver.quit()
    finally:
       if driver:
           driver.quit()
    with counter_lock:
        counter += 1
        with open('progress.txt', 'w') as f:
            f.write(str(float(counter / len(accreditation_Code_List))))
        print(f"Processed {counter} out of {len(accreditation_Code_List)}")
    

    return search_results_data, transfer_history_data

def scrape_all(accreditation_Code_List):
    global should_stop
    search_results_all = []
    transfer_history_all = []


    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        results = executor.map(scrape, accreditation_Code_List)

    for result in results:
        search_results, transfer_history = result
        search_results_all.extend(search_results)
        transfer_history_all.extend(transfer_history)

    return search_results_all, transfer_history_all
    
if __name__ == '__main__':
    max_workers = 50    
    if len(sys.argv) > 1:
        max_workers = int(sys.argv[1])
    print(f'running with {max_workers} workers')
    accreditation_Code_List = pd.read_pickle('accreditation_code_list.pkl')
    
    accreditation_Code_List = accreditation_Code_List.tolist()
    accreditation_Code_List = accreditation_Code_List[:3]
   
    s_headers = "Current owner","Accreditation code","Fuel source","Generation year","Creation year","Generation state","Status","Certificate serial number","Certificate quantity"
    t_headers = "Transferred date","Seller","Buyer","Certificate Number","accreditation_Code"
    
    counter = 0
    search_results_data, transfer_history_data = scrape_all(accreditation_Code_List)

    search_results_data = pd.DataFrame(search_results_data, columns=s_headers)
    transfer_history_data = pd.DataFrame(transfer_history_data, columns=t_headers)
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

    search_results_filename = f"Scraper_run_search_results_{timestamp}.pkl"
    transfer_history_filename = f"Scraper_run_transfer_history_{timestamp}.pkl"

    search_results_data.to_pickle(search_results_filename)
    transfer_history_data.to_pickle(transfer_history_filename)

    open('progress.txt', 'w').close()