import os
import csv
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from dotenv import load_dotenv, dotenv_values

def create_env_file():
    """Creates or updates the .env file with default username and password."""
    env_path = os.path.join(os.path.dirname(os.path.abspath(_file_)), 'eli.env')
    if not os.path.exists(env_path):
        with open(env_path, 'w', encoding='utf-8') as env_file:
            env_file.write("uname=202306380\n")
            env_file.write("pword=Zeuskidde2006@@\n")
        print(f"eli.env file created at: {env_path}")
    else:
        print("eli.env file already exists.")

# Create or update the .env file
create_env_file()

# Load .env file
env_path = os.path.join(os.path.dirname(os.path.abspath(_file_)), 'eli.env')
load_dotenv(env_path)

# Read credentials from .env file
uname = os.getenv("uname")
pword = os.getenv("pword")

if not uname or not pword:
    raise ValueError("Username (uname) or password (pword) is not set in eli.env.")

print(f"Read uname: {uname} and pword from eli.env")

# Dynamic ChromeDriver path
base_dir = os.path.dirname(os.path.abspath(_file_))
chromedriver_path = os.path.join(base_dir, 'chromedriver-win64', 'chromedriver.exe')
if not os.path.exists(chromedriver_path):
    raise FileNotFoundError(f"ChromeDriver not found: {chromedriver_path}")

# Set up Selenium ChromeDriver
service = Service(chromedriver_path)
driver = webdriver.Chrome(service=service)

try:
    # Open the login page
    driver.get("https://sso.aztu.edu.az/")

    # Wait for username input field
    username_input = WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//input[@placeholder='\u0130stifadə\u00e7i ad\u0131']"))
    )

    # Wait for password input field
    password_input = WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//input[@placeholder='\u015eifr\u0259']"))
    )

    # Enter credentials
    username_input.send_keys(uname)
    password_input.send_keys(pword)

    # Click login button
    login_button = driver.find_element(By.XPATH, "//button[@type='submit']")
    login_button.click()

    # Wait for the student portal link
    WebDriverWait(driver, 30).until(
        EC.presence_of_element_located((By.LINK_TEXT, "Tələbə keçid"))
    )

    # Navigate to student portal
    student_link = driver.find_element(By.LINK_TEXT, "Tələbə keçid")
    student_link.click()

    # Navigate to subjects
    fenler_link = WebDriverWait(driver, 20).until(
        EC.element_to_be_clickable((By.XPATH, "//a[span[contains(text(), 'Fənlər')]]"))
    )
    fenler_link.click()

    # Navigate to Python course
    python_link = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//a[contains(@href, 'lecture_name=Python proqramlaşdırma dili')]"))
    )
    python_link.click()

    # Navigate to attendance
    attendance_link = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//a[contains(text(), 'Davamiyyət')]")
    ))
    attendance_link.click()

    # Wait for the table to load
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//table[@id='datatable-buttons']"))
    )

    # Find the table
    table = driver.find_element(By.XPATH, "//table[@id='datatable-buttons']")

    # Find the date row
    date_row = table.find_element(By.XPATH, ".//tr[th[contains(text(),'Dərsin tarixi')]]")
    date_columns = date_row.find_elements(By.XPATH, ".//th[contains(@class, 'list_text6')]//font")

    # Extract dates
    dates = [col.text.strip() for col in date_columns if col.text.strip()]

    # Create CSV file
    csv_file_path = os.path.join(base_dir, 'cedvell.csv')
    with open(csv_file_path, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)

        # Write headers
        writer.writerow(dates)

        # Read student rows
        rows = table.find_elements(By.TAG_NAME, "tr")
        for row in rows[1:]:
            columns = row.find_elements(By.TAG_NAME, "td")
            if len(columns) > 3:
                student_name = columns[2].text.strip()
                attendance_status = [col.text.strip() for col in columns[3:]]
                writer.writerow([student_name] + attendance_status)

    print(f"Attendance table successfully written to CSV: {csv_file_path}")

finally:
    driver.quit()
