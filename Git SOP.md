# Git SOP

## Install Git:
Download and install Git on your local computer. You can find the installer for your operating system at https://git-scm.com/downloads.

## Clone the Repository:
Once Git is installed, navigate to the directory where you want to work on your local machine and clone the GitHub repository. Use the following command, replacing <repository-url> with the actual URL of your repository:

```git clone <repository-url>```

## Navigate into the repo:
``` CD / repo name```


## Configure Your Identity:
Set up your name and email address for Git. This information will be used to identify you in the commit history.


```git config --global user.name "Your Name"```
```git config --global user.email "your.email@example.com"```

## Create your own Branch:
Before making changes, it's a good practice to create a new branch for your work. This allows you to work independently and avoid conflicts with the main codebase.


```git checkout -b your-feature-branch```

## Make Changes and Commit:

Now, make the necessary changes to the files in your local repository. After you've made your changes, commit them with a meaningful commit message.

```git add .```


```git commit -m "Your descriptive commit message here"```

## Pull Changes from the Remote Repository:
Before pushing your changes, it's essential to ensure you have the latest code from the remote repository. This helps prevent conflicts.


```git pull origin main```

## Push Your Changes:
Once you have pulled the latest changes and resolved any conflicts, you can push your branch to the remote repository.


```git push origin your-feature-branch```

## Create a Pull Request:
On GitHub, go to your repository and click on the "Pull Requests" tab. Click on "New Pull Request," select your feature branch as the base, and the main branch as the compare branch. Add a descriptive title and details about the changes you've made. Then, submit the pull request for review by your team.


## Review and Merge:
Your team members will review your changes, provide feedback, and approve the pull request if everything looks good. Once approved, the changes can be merged into the main branch.


Sync with the Main Branch:
Regularly pull the latest changes from the main branch into your feature branch to keep it up-to-date during development.

```git pull origin main```

# Delete Feature Branch:
After your changes have been merged into the main branch, you can delete your feature branch if it's no longer needed.


```git branch -d your-feature-branch```

