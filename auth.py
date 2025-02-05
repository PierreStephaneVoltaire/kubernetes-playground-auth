import os
import boto3

GROUP_NAME = os.getenv("GROUP_NAME_ENV", "readonly")
cognito_client = boto3.client("cognito-idp")
def lambda_handler(event, context):
    try:
        user_pool_id = event["userPoolId"]
        user_name = event["userName"]
        cognito_client.admin_add_user_to_group(
            UserPoolId=user_pool_id,
            Username=user_name,
            GroupName=GROUP_NAME
        )
        print(f"User {user_name} added to group {GROUP_NAME} in pool {user_pool_id}")
    except Exception as e:
        print(f"Error adding user to group: {str(e)}")
    return event
