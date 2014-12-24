(ql:quickload :drakma)
(ql:quickload :yason)
(ql:quickload :alexandria)

;デフォルトのエンコードを指定
(setf drakma:*drakma-default-external-format* :utf-8)

; ボディを文字列で取得するために、テキストとして判定される Content-Type を追加
(pushnew '("application" . "json") drakma:*text-content-types* :test #'equal)

(multiple-value-bind (body status)
    (drakma:http-request "https://qiita.com/api/v1/tags/common-lisp/items")
  (when (= status 200)
    (defvar *qiita-json-array* body)))

;QiitaのAPIからのレスポンスをCLの配列としてresultに格納
(let* ((yason:*parse-json-arrays-as-vectors* t) (result (yason:parse *qiita-json-array*)))
;result というjson arrayに対してloopを回しeach-articleにそれぞれ格納
  (loop for each-article across result do
;each-articleが一つの記事の情報に該当し、それらの情報をREPL上に表示
  (let ((article (alexandria:copy-hash-table each-article)))
       (let ((id (gethash "id" article))
             (user (gethash "user" article))
             (title (gethash "title" article))
             (updated_at (gethash "updated_at" article))
             (url (gethash "url" article)))
         (let ((user_name (gethash "url_name" user)))
           (format t "article-id: ~A~%user: ~A~%title: ~A~%update_at: ~A~%url: ~A~%~%~%" id user_name title updated_at url))))))

;もう一つのAPIに関しても同じことを行う
