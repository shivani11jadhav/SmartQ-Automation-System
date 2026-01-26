# SmartQ Waiting Time Prediction Logic
# Developed by Team Innovator (Shivani Pratap Jadhav)

def calculate_waiting_time(queue_length, average_service_time):
    """
    Calculate estimated waiting time based on current queue and history.
    Args:
        queue_length (int): Number of people ahead in the queue.
        average_service_time (int): Average minutes spent per person.
    Returns:
        int: Estimated time in minutes.
    """
    # Base calculation
    base_time = queue_length * average_service_time
    
    # Adding a small buffer (2-5 mins) for real-world variations
    buffer_time = 3 
    
    predicted_time = base_time + buffer_time
    return predicted_time

# Live Scenario Example
current_people = 12
avg_mins_per_person = 5

result = calculate_waiting_time(current_people, avg_mins_per_person)
print(f"Estimated Waiting Time: {result} minutes")
