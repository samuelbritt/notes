# Notes
Markdown-based notes.

## Examples

Open the notes directory with your editor.

```powershell
> on
```

Create and open a new, untitled note.

```powershell
> nn
```

Create a new note, and give it a title and some tags.

```powershell
> nn 'My favorite breakfast' -Tag food, spam, eggs
```

Find all notes with a given tag.

```powershell
> fn -Tag food

Name    : 2018-05-19_202426-My-favorite-breakfast.md
Title   : My favorite breakfast
Path    : C:\Users\sbritt\notes-test\2018-05-19_202426-My-favorite-breakfast.md
Created : 5/19/2018 8:24:26 PM
Updated : 5/19/2018 8:24:26 PM
Tags    : {food, spam, eggs}

Name    : 2018-05-19_202454-My-favorite-lunch.md
Title   : My favorite lunch
Path    : C:\Users\sbritt\notes-test\2018-05-19_202454-My-favorite-lunch.md
Created : 5/19/2018 8:24:54 PM
Updated : 5/19/2018 8:24:54 PM
Tags    : {food, salad}
```
