# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Define environment variables
ENV FLASK_APP=app.py FLASK_RUN_HOST=0.0.0.0

# Expose port 3000
EXPOSE 3000

# Run the application
CMD ["flask", "run", "--host=0.0.0.0", "--port=3000"] 