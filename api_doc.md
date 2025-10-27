# **Moebooru/Danbooru API Documentation (v1.13.0+ update.3)**

Moebooru offers an API that is mostly compatible with the Danbooru API (version 1.13.0) to facilitate scripting. Interaction requires basic HTTP GET and POST capabilities, and the ability to parse XML or JSON responses is highly recommended.

## **Basics**

### **Request Methods**

HTTP defines two primary request methods you will use: **GET** and **POST**.

* **GET**: Typically used for API calls that only retrieve data (e.g., listing posts).  
* **POST**: Required for API calls that change the state of the database (e.g., creating, updating, or deleting something).

### **URL Structure**

In this API, the URL structure is analogous to a function call:  
/controller/action.format?parameters  
**Example:** /post.xml?limit=1

* **Controller:** The resource you are working with (e.g., post for posts, tag for tags).  
* **Action:** The operation you are performing (e.g., index for listing/retrieving, create, update, destroy). If no action is specified (like in the example /post.xml), the default action is usually index.  
* **Format:** The desired response format:  
  * .xml: For XML responses.  
  * .json: For JSON responses.  
  * *(Nothing)*: For HTML responses (usually only for web browser access).

## **Responses**

API calls that change the state (POST requests) will return a single element response indicating success or failure.

### **XML Response Example (Failure)**

\<?xml version="1.0" encoding="UTF-8"?\>  
\<response success="false" reason="duplicate"/\>

### **JSON Response Example (Failure)**

{  
  "success": false,  
  "reason": "duplicate"  
}

### **HTTP Status Codes**

In addition to the standard codes, the API uses custom status codes in the 4xx range for specific application errors.

| Status Code | Meaning |
| :---- | :---- |
| **200 OK** | Request was successful. |
| **403 Forbidden** | Access denied (e.g., insufficient permissions). |
| **404 Not Found** | The resource was not found. |
| **420 Invalid Record** | Record could not be saved (e.g., validation failed). |
| **421 User Throttled** | User is throttled; try again later. |
| **422 Locked** | The resource is locked and cannot be modified. |
| **423 Already Exists** | Resource already exists. |
| **424 Invalid Parameters** | The given parameters were invalid. |
| **500 Internal Server Error** | An unknown server error occurred. |
| **503 Service Unavailable** | Server cannot currently handle the request; try again later. |

## **Logging In**

Some actions require authentication. You can authenticate by specifying two parameters with every request:

* **login**: Your login name.  
* **password\_hash**: Your SHA1 hashed password.

**CRITICAL SECURITY NOTE:** Simply hashing your plain password will NOT work. The actual string that must be hashed is: "So-I-Heard-You-Like-Mupkids-?--your-password--".

## **Posts**

### **List**

Base URL: /post.xml (or /post.json)

| Parameter | Description |
| :---- | :---- |
| **limit** | How many posts to retrieve (hard limit of 100 per request). |
| **page** | The page number. |
| **tags** | The tags to search for (any tag combination that works on the website). |

### **Create**

Base URL: /post/create.xml  
Mandatory fields: post\[tags\] and either post\[file\] or post\[source\].

| Parameter | Description |
| :---- | :---- |
| **post\[tags\]** | A space-delimited list of tags. (Mandatory) |
| **post\[file\]** | The file data encoded as a multipart form. |
| **post\[rating\]** | The rating: safe, questionable, or explicit. |
| **post\[source\]** | If a URL, the system will download the file. |
| **post\[is\_rating\_locked\]** | Set to true to lock the rating. |
| **post\[is\_note\_locked\]** | Set to true to lock the notes. |
| **post\[parent\_id\]** | The ID of the parent post. |
| **md5** | Optional MD5 hash to verify the file after upload. |

Failure Reasons: MD5 mismatch, duplicate (with location attribute), or other.  
Success: Response will include a location attribute pointing to the new post's relative URL.

### **Update**

Base URL: /post/update.xml

| Parameter | Description |
| :---- | :---- |
| **id** | The ID number of the post to update. (Required) |
| **post\[tags\]** | New tags (optional). |
| **post\[file\]** | New file data (optional). |
| **post\[rating\]** | New rating (optional). |
| **post\[source\]** | New source URL (optional). |
| *Other parameters from Create* | All other post attributes can be updated. |

### **Destroy**

Base URL: /post/destroy.xml  
Requires login and moderator status or ownership of the post.

| Parameter | Description |
| :---- | :---- |
| **id** | The ID number of the post to delete. |

### **Revert Tags**

Base URL: /post/revert\_tags.xml

| Parameter | Description |
| :---- | :---- |
| **id** | The post ID number to update. |
| **history\_id** | The ID number of the tag history entry to revert to. |

### **Vote**

Base URL: /post/vote.xml  
You can only vote once per post per IP address.

| Parameter | Description |
| :---- | :---- |
| **id** | The post ID number to vote on. |
| **score** | Set to 1 to vote up, or \-1 to vote down. |

**Failure Reasons:** already voted, invalid score.

## **Tags**

### **List**

Base URL: /tag.xml

| Parameter | Description |
| :---- | :---- |
| **limit** | How many tags to retrieve. Set to 0 to return every tag. |
| **page** | The page number. |
| **order** | Can be date, count, or name. |
| **id** | The specific ID number of the tag. |
| **after\_id** | Return all tags with an ID greater than this value. |
| **name** | The exact name of the tag. |
| **name\_pattern** | Search for any tag that contains this fragment in its name. |

### **Update**

Base URL: /tag/update.xml

| Parameter | Description |
| :---- | :---- |
| **name** | The name of the tag to update. (Required) |
| **tag\[tag\_type\]** | The tag type: 0 (General), 1 (Artist), 3 (Copyright), 4 (Character). |
| **tag\[is\_ambiguous\]** | 1 for true, 0 for false. |

### **Related**

Base URL: /tag/related.xml

| Parameter | Description |
| :---- | :---- |
| **tags** | The tag names to query (comma or space-separated). |
| **type** | Restrict results to a specific type: general, artist, copyright, or character. |

## **Artists**

### **List**

Base URL: /artist.xml

| Parameter | Description |
| :---- | :---- |
| **name** | The name (or fragment of the name) of the artist. |
| **order** | Can be date or name. |
| **page** | The page number. |

### **Create**

Base URL: /artist/create.xml

| Parameter | Description |
| :---- | :---- |
| **artist\[name\]** | The artist's name. (Required) |
| **artist\[urls\]** | A whitespace-delimited list of URLs associated with the artist. |
| **artist\[alias\]** | The name of the artist this entry is an alias for. |
| **artist\[group\]** | The name of the group or circle this artist is a member of. |

### **Update**

Base URL: /artist/update.xml

| Parameter | Description |
| :---- | :---- |
| **id** | The ID of the artist to update. (Required) |
| *Other parameters from Create* | All other artist attributes can be updated. |

### **Destroy**

Base URL: /artist/destroy.xml  
Must be logged in.

| Parameter | Description |
| :---- | :---- |
| **id** | The ID of the artist to destroy. |

## **Comments**

### **Show**

Base URL: /comment/show.xml (Retrieves a single comment)

| Parameter | Description |
| :---- | :---- |
| **id** | The ID number of the comment to retrieve. |

### **Create**

Base URL: /comment/create.xml

| Parameter | Description |
| :---- | :---- |
| **comment\[post\_id\]** | The post ID number the comment is responding to. (Required) |
| **comment\[body\]** | The body of the comment. (Required) |
| **comment\[anonymous\]** | Set to 1 to post anonymously. |

### **Destroy**

Base URL: /comment/destroy.xml  
Requires login and moderator status or ownership of the comment.

| Parameter | Description |
| :---- | :---- |
| **id** | The ID number of the comment to delete. |

## **Wiki**

*All titles must be exact (case and whitespace do not matter).*

### **List**

Base URL: /wiki.xml (Retrieves a list of every wiki page)

| Parameter | Description |
| :---- | :---- |
| **order** | How to order the pages: title or date. |
| **limit** | The number of pages to retrieve. |
| **page** | The page number. |
| **query** | A word or phrase to search for in the title/body. |

### **Create**

Base URL: /wiki/create.xml

| Parameter | Description |
| :---- | :---- |
| **wiki\_page\[title\]** | The title of the wiki page. (Required) |
| **wiki\_page\[body\]** | The body of the wiki page. (Required) |

### **Update**

Base URL: /wiki/update.xml  
Possible Error Reason: "Page is locked"

| Parameter | Description |
| :---- | :---- |
| **title** | The current title of the wiki page to update. (Required) |
| **wiki\_page\[title\]** | The new title of the wiki page. |
| **wiki\_page\[body\]** | The new body of the wiki page. |

### **Show**

Base URL: /wiki/show.xml

| Parameter | Description |
| :---- | :---- |
| **title** | The title of the wiki page to retrieve. (Required) |
| **version** | The specific version of the page to retrieve. |

### **Destroy**

Base URL: /wiki/destroy.xml  
Must be logged in as a moderator.

| Parameter | Description |
| :---- | :---- |
| **title** | The title of the page to delete. |

### **Lock / Unlock**

Base URLs: /wiki/lock.xml and /wiki/unlock.xml  
Must be logged in as a moderator.

| Parameter | Description |
| :---- | :---- |
| **title** | The title of the page to lock or unlock. |

### **Revert**

Base URL: /wiki/revert.xml  
Possible Error Reason: "Page is locked"

| Parameter | Description |
| :---- | :---- |
| **title** | The title of the wiki page to update. (Required) |
| **version** | The version number to revert to. (Required) |

### **History**

Base URL: /wiki/history.xml

| Parameter | Description |
| :---- | :---- |
| **title** | The title of the wiki page to retrieve versions for. |

## **Notes**

### **List**

Base URL: /note.xml

| Parameter | Description |
| :---- | :---- |
| **post\_id** | The post ID number to retrieve notes for. |

### **Search**

Base URL: /note/search.xml

| Parameter | Description |
| :---- | :---- |
| **query** | A word or phrase to search for. |

### **History**

Base URL: /note/history.xml  
(Specifying nothing returns a list of every note version.)

| Parameter | Description |
| :---- | :---- |
| **limit** | How many versions to retrieve. |
| **page** | The offset/page number. |
| **post\_id** | The post ID number to retrieve note versions for. |
| **id** | The note ID number to retrieve versions for. |

### **Revert**

Base URL: /note/revert.xml  
Possible Error Reason: "Post is locked"

| Parameter | Description |
| :---- | :---- |
| **id** | The note ID to update. (Required) |
| **version** | The version to revert to. (Required) |

### **Create/Update**

Base URL: /note/update.xml  
(If id is supplied, it's an update; otherwise, it's a creation.)  
Possible Error Reason: "Post is locked"

| Parameter | Description |
| :---- | :---- |
| **id** | If updating, the note ID number. |
| **note\[post\_id\]** | The post ID this note belongs to. (Required for creation) |
| **note\[x\]** | The X coordinate of the note box. |
| **note\[y\]** | The Y coordinate of the note box. |
| **note\[width\]** | The width of the note box. |
| **note\[height\]** | The height of the note box. |
| **note\[is\_active\]** | Whether the note is visible: 1 (active), 0 (inactive). |
| **note\[body\]** | The note message. (Required) |

## **Users**

### **Search**

Base URL: /user.xml  
(No parameters returns a listing of all users.)

| Parameter | Description |
| :---- | :---- |
| **id** | The ID number of the user. |
| **name** | The name of the user. |

## **Forum**

### **List**

Base URL: /forum.xml  
(No parameters returns a list of all parent topics.)

| Parameter | Description |
| :---- | :---- |
| **parent\_id** | The ID number of the parent topic to retrieve responses for. |

## **Pools**

### **List Pools**

Base URL: /pool.xml  
(No parameters returns a list of all pools.)

| Parameter | Description |
| :---- | :---- |
| **query** | Search for a pool title. |
| **page** | The page number. |

### **List Posts**

Base URL: /pool/show.xml

| Parameter | Description |
| :---- | :---- |
| **id** | The pool ID number. (Required) |
| **page** | The page number. |

### **Update**

Base URL: /pool/update.xml

| Parameter | Description |
| :---- | :---- |
| **id** | The pool ID number. (Required) |
| **pool\[name\]** | The new name. |
| **pool\[is\_public\]** | 1 or 0\. |
| **pool\[description\]** | A description of the pool. |

### **Create**

Base URL: /pool/create.xml

| Parameter | Description |
| :---- | :---- |
| **pool\[name\]** | The pool name. (Required) |
| **pool\[is\_public\]** | 1 or 0\. |
| **pool\[description\]** | A description of the pool. |

### **Destroy**

Base URL: /pool/destroy.xml

| Parameter | Description |
| :---- | :---- |
| **id** | The pool ID number. (Required) |

### **Add Post / Remove Post**

Base URLs: /pool/add\_post.xml and /pool/remove\_post.xml  
Possible Error Reasons: "Post already exists", "access denied"

| Parameter | Description |
| :---- | :---- |
| **pool\_id** | The pool to modify. (Required) |
| **post\_id** | The post to add or remove. (Required) |

## **Favorites**

### **List Users**

Base URL: /favorite/list\_users.json  
Note: There is no XML API for this action.

| Parameter | Description |
| :---- | :---- |
| **id** | The post ID. |

## **Change Log**

### **1.13.0 \+ update.3**

* Removed /index from API URLs.

### **1.13.0 \+ update.2**

* Re-added favorite/list\_users API.

### **1.13.0 \+ update.1**

* Added documentation for Pools.

### **1.13.0**

* Changed interface for artists to use new URL system.  
* JSON requests now end in a .json suffix.  
* Renamed some error reason messages.  
* Removed comment/index from API.  
* Removed url and md5 parameters from artist search (now passed to the name parameter).

### **1.8.1**

* Removed post\[is\_flagged\] attribute.