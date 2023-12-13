import os
import shutil
import tkinter as tk
from tkinter import filedialog
from tkinter import messagebox


def select_path():
    path = filedialog.askdirectory()
    path_entry.delete(0, tk.END)
    path_entry.insert(0, path)


def confirm():
    project_name = name_entry.get()
    project_path = path_entry.get()
    new_project = os.path.join(project_path, project_name)
    msg = "Warning", "The `{}` already exists,Do you want to overwrite it?".format(project_name)
    if os.path.exists(new_project):
        if messagebox.askquestion(*msg) == 'no':
            return
        shutil.rmtree(new_project)

    try:
        shutil.copytree("./template", new_project)
        cmd = "code {}".format(new_project)
        print("Open project:", cmd)
        os.system(cmd)
        root.quit()
    except Exception as err:
        print("Error:", err)


root = tk.Tk()
root.title("Create Project")

# 工程名称
name_label = tk.Label(root, text="Name")
name_label.grid(row=0, column=0, padx=2, pady=10)
name_entry = tk.Entry(root, width=60)
name_entry.insert(0, 'Demo')
name_entry.grid(row=0, column=1, padx=2, pady=10)

# 工程存储路径
path_label = tk.Label(root, text="Location")
path_label.grid(row=1, column=0, padx=2, pady=10)
path_entry = tk.Entry(root, width=60)

default_path = os.path.join(os.path.expanduser("~"), "cppProjects")
path_entry.insert(0, default_path)
path_entry.grid(row=1, column=1, padx=2, pady=10)
path_button = tk.Button(root, text="Open", command=select_path)
path_button.grid(row=1, column=2, padx=2, pady=10)

# 确认和取消按钮
button_frame = tk.Frame(root)  # 创建新的 Frame
button_frame.grid(row=2, column=0, columnspan=3, padx=2, pady=10)  # 将 Frame 放入网格
confirm_button = tk.Button(button_frame, text="Ok", command=confirm, width=20)  # 设置宽度为 20
confirm_button.pack(side=tk.LEFT, padx=2, pady=10)  # 使用 pack 方法将按钮放入 Frame
cancel_button = tk.Button(button_frame, text="Cancel", command=root.quit, width=20)  # 设置宽度为 20
cancel_button.pack(side=tk.RIGHT, padx=2, pady=10)  # 使用 pack 方法将按钮放入 Frame

root.mainloop()
